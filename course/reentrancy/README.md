
# Reentrancy Attacks

**目次**
- [Reentrancy Attackとは](#reentrancy-attackとは)
  - [Reentrancy Attackの具体例](#reentrancy-attackの具体例)
  - [演習](#演習)
- [Reentrancy Attackの対策](#reentrancy-attackの対策)
  - [Checks-Effects-Interactionsパターンの遵守](#checks-effects-interactionsパターンの遵守)
  - [Mutex (Reentrancy Guard)の導入](#mutex-reentrancy-guardの導入)
  - [Pull Paymentメカニズムへの変更](#pull-paymentメカニズムへの変更)
- [Reentrancy Attackの類型](#reentrancy-attackの類型)
  - [Single-Function Reentrancy Attack](#single-function-reentrancy-attack)
    - [演習](#演習-1)
  - [Cross-Function Reentrancy Attack](#cross-function-reentrancy-attack)
    - [演習](#演習-2)
  - [Cross-Contract Reentrancy Attack](#cross-contract-reentrancy-attack)
    - [演習](#演習-3)
  - [Cross-Chain Reentrancy Attack](#cross-chain-reentrancy-attack)
  - [Read-Only Reentrancy Attack](#read-only-reentrancy-attack)
    - [演習](#演習-4)
- [発展: Transient Storage Opcodes (`TLOAD`/`TSTORE`)](#発展-transient-storage-opcodes-tloadtstore)
- [参考: Reentrancy Attackを利用するCTFの問題](#参考-reentrancy-attackを利用するctfの問題)


## Reentrancy Attackとは

Reentrancy Attackとは、「ある関数の呼び出し中に、再度その関数あるいは（状態を共有する）別の関数を呼び出すことで、状態に不整合を起こす攻撃」のことです。

### Reentrancy Attackの具体例

具体的にReentrancy Attackを見ていきましょう。
次の`Vault`コントラクトについて考えてみます。
以下、Solidityのバージョンは全て`^0.8.13`です。

```solidity
contract Vault {
    mapping(address => uint256) public balanceOf;

    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
    }

    function withdrawAll() public {
        require(balanceOf[msg.sender] > 0);
        (bool success,) = msg.sender.call{value: balanceOf[msg.sender]}("");
        require(success);
        balanceOf[msg.sender] = 0;
    }
}
```

`Vault`コントラクトには、`deposit`関数と`withdrawAll`関数の2つの関数が実装されています。
`deposit`関数をEtherの送金付きで呼び出すと、そのEtherの額が`balanceOf[msg.sender]`に加算されます。
そして、`withdrawAll`関数でその預けたEtherを全額引き出せます。

この`Vault`コントラクトにはReentrancy Attackが適用できる脆弱性があります。
初期状態として、例えば、`Vault`コントラクトが1 ether保管しているとします。

攻撃者は以下の流れでその1 etherを奪取できます。
1. `deposit`関数で1 ether送金する
2. `withdrawAll`関数を呼び出す
3. `withdrawAll`関数中の`call`による1 etherの送金を、receive Ether関数で受け取り、再度`withdrawAll`関数を呼び出す

図に表すと次のようになります。

```mermaid
sequenceDiagram
    participant Attacker
    participant Vault

	Attacker ->>+ Vault: 1 etherをdeposit
	Vault -->>- Attacker: (deposit終了)
	Attacker ->>+ Vault: withdrawAll①
	Vault ->>+ Attacker: 1 ether送金①
	Attacker ->>+ Vault: withdrawAll②
	Vault ->>+ Attacker: 1 ether送金②
	Note over Attacker: 残高: 2 ether
	Attacker -->>- Vault: (送金②終了)
	Vault -->>- Attacker: (withdrawAll②終了)
	Attacker -->>- Vault: (送金①終了)
	Vault -->>- Attacker: (withdrawAll①終了)
```

このように、関数の呼び出し中に、もう一度その関数を呼び出すことが「reentrancy」と言われる所以になっています。

それでは、なぜこれでEtherが奪取されてしまうかについて詳しく追っていきます。
まず、原因の一つに`balanceOf`の更新が`call`の後にあることが挙げられます。
1回目の`withdraw`関数を呼び出すと、`balanceOf[msg.sender]`が更新されないまま、2回目の`withdraw`関数が実行されます。
つまり、残高チェックである`balanceOf[msg.sender] >= amount`の条件が満たされたままです。
関数の最後で`balanceOf[msg.sender]`が`0`になりますが、更新のタイミングが遅く、これでは不適切です。

参考までに、コードレベルで具体的に以下の処理が行われます。細かい処理を確認したい方は読んでみてください。
- 攻撃者が用意したコントラクトから`withdrawAll`関数が呼び出される
- `require(balanceOf[msg.sender] > 0);`のチェックが行われる
	- `balanceOf[msg.sender]`は1 ether
- `msg.sender.call{value: balanceOf[msg.sender]}("")`が実行される
	- `msg.sender`は攻撃者が用意したコントラクトアドレス
	- `balanceOf[msg.sender]`は1 ether
- 攻撃者が用意したコントラクトの`receive`関数にフォールバックする
- 再度`withdrawAll`関数が呼び出される
-  `require(balanceOf[msg.sender] > 0);`のチェックが行われる
	-  `balanceOf[msg.sender]`は更新されていないのでまだ1 etherのまま
-  `msg.sender.call{value: balanceOf[msg.sender]}("")`が実行される
- 攻撃者が用意したコントラクトの`receive`関数にフォールバックする
- この2回目の`receive`関数の実行が終了
- 2回目の`msg.sender.call`の実行が終了し、`msg.sender`への1 etherの送金が完了する
- 2回目の`withdrawAll`関数の`require(success);`のチェックが行われる
	- `success`は`true`
- 2回目の`withdrawAll`関数の`balanceOf[msg.sender] = 0;`が実行される
- 2回目の`withdrawAll`関数の実行が終了する
- 1回目の`receive`関数の実行が終了
- 1回目の`msg.sender.call`の実行が終了し、`msg.sender`への1 etherの送金が完了する
	- トータルで2 ether送金されたことになる
- 1回目の`withdrawAll`関数の`require(success);`のチェックが行われる
	- この`success`も`true`
- 1回目の`withdrawAll`関数の`balanceOf[msg.sender] = 0;`が実行される
	- 更新する前の時点で`balanceOf[msg.sender]`は既に`0`
- 1回目の`withdrawAll`関数の実行が終了
- 攻撃者が用意したコントラクトに処理が戻る

### 演習

`reentrancy/challenge-single-function`ディレクトリの`Challenge.t.sol`を完成させて、`Vault`コントラクトへのReentrancy Attackを成功させてください。

以下のコマンドを実行して、テストがパスしたら成功です。

```
forge test -vvv --match-path course/reentrancy/challenge-single-function/Challenge.t.sol
```

以下のコメントの間に自分のコード（攻撃コントラクト含む）を書いてください。それ以外は編集しないでください。

```
////////// YOUR CODE GOES HERE //////////

////////// YOUR CODE END //////////
```

## Reentrancy Attackの対策

Reentrancy Attackへの一般的な対策として、次の3つが挙げられます。
- Checks-Effects-Interactionsパターンの遵守
- Mutex (ReentrancyGuard)の導入
- Pull Paymentメカニズムへの変更

最も重要な対策はChecks-Effects-Interactionsパターンの遵守で、これが守られていないと他の2つの対策を行っていても攻撃される可能性があります。

ここでは、これら3つの対策について説明します。

### Checks-Effects-Interactionsパターンの遵守

Checks-Effects-Interactionsパターンとは、その名の通り、「Checks」「Effects」「Interactions」の順番に処理を書きましょうというデザインパターンです。
C-E-IやCEIと略されることがあります。

最初の`Vault`コントラクトの`withdrawAll`関数を考えてみます。

```solidity
    function withdrawAll() public {
        require(balanceOf[msg.sender] > 0);
        (bool success,) = msg.sender.call{value: balanceOf[msg.sender]}("");
        require(success);
        balanceOf[msg.sender] = 0;
    }
```

この`withdrawAll`関数の処理をそれぞれ「Checks」「Effects」「Interactions」に当てはめると次のようになります。
- Check: `require(balanceOf[msg.sender] > 0);`
- Effect: `balanceOf[msg.sender] = 0;`
- Interaction: `msg.sender.call{value: balanceOf[msg.sender]}("");`

つまり、この`withdrawAll`関数では、Checkの後にEffectではなくInteractionを置いてしまっているということです。
これを、Checks-Effects-Interactionsパターンに従って、処理の順番を変えてみると次のようになります。

```solidity
    function withdrawAll() public {
        require(balanceOf[msg.sender] > 0);
        balanceOf[msg.sender] = 0;
        (bool success,) = msg.sender.call{value: balanceOf[msg.sender]}("");
        require(success);
    }
```

こうすれば、先程説明した攻撃を行っても、1回目の`withdrawAll`関数の`msg.sender.call`実行前に`balanceOf[msg.sender]`の値が`0`に設定されるため、2回目の`withdrawAll`関数実行時には`balanceOf[msg.sender] > 0`を満たせずに実行がリバートします。

以上のように、reentrantされる可能性のある関数では、Checks-Effects-Interactionsパターンに従うことで、状態の不整合を防ぐことができます。

### Mutex (Reentrancy Guard)の導入

Reentrancy Attackへの対策として、そもそも関数実行中に関数が呼ばれることを禁止するという対策があります。
つまり、Mutexを導入するということで、そのMutexのことをブロックチェーン領域ではReentrancy Guardと呼ぶことが多いです。

対策の仕方は簡単で、関数が実行中かどうかのフラグをコントラクトの変数で保持しておいて、関数の実行前にそのフラグをチェックして、フラグが立っていないならフラグを立て処理を始め、関数終了時にフラグをクリアするというものです。

OpenZeppelinがこのReentrancy Guardを実現するための標準となるコントラクト`ReentrancyGuard`を用意しています（[参考](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.1/contracts/security/ReentrancyGuard.sol#L22)）。
コードは以下です（公式のコードからコメントを省いて引用しています）。

```solidity
abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        _status = _NOT_ENTERED;
    }

    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}
```

保護したい関数を持つコントラクトにこの`ReentrancyGuard`を継承させて、その関数に`nonReentrant`モディファイアを修飾させるだけで導入できます。

ただし、後述するCross-Contract Reentrancy AttackとRead-Only Reentrancy Attackに対してはこの対策が通用しません。
理由は後述します。

### Pull Paymentメカニズムへの変更

Pull Paymentメカニズムとは、Etherを受取人に送金する（プッシュする）のではなく、受取人がEtherを受け取る（プルする）仕組みのことです。
Pull over Pushとも呼ばれることもあります。

いまいちピンとこないと思うので、具体的に説明します。
Reentrancy Attackが起こる原因の一つは、ある関数の処理が行われている途中に、攻撃者へのコントラクトに制御権が移っていることにあります。
その関数の処理がシンプルな処理であればまだいいのですが、複雑であればあるほどChecks-Effects-Interactionsパターンに違反するミスが発生しやすくなります。

そのリスクを軽減するために、Interactions部分であるEtherの送金の処理を別の関数に分け、送金は別のトランザクションでないと実行できないようにするとどうなるでしょうか。
コントラクト内部で各アドレスの残高を記録して、送金はそのマッピング変数を変更するだけにしておき、実際の送金処理は後でユーザーが別途行わなくてはいけないことになります。
こうすれば、攻撃者へのコントラクトに制御権が移るのは単純な送金関数のみになり、その単純な送金関数についてChecks-Effects-Interactionsパターンのチェックをすればよくなります。

ユーザーによるEtherの受け取りまで実際のEtherがやり取りされないため、イメージとしてはネッティングに近いです。

Pull Paymentメカニズムは、Reentrancy Attackの対策の他にも、送金の失敗リスクをユーザーに転嫁しているという側面があります。
例えば、プッシュ型で送金を行ったときに、送金先のコントラクトが常にリバートするようになっていると、コントラクトがその状態にロックされてしまいます。
Pull Paymentメカニズムを使えば、送金をする責任はユーザーにあるので、そのようなリスクはありません。

ただし、Pull PaymentメカニズムはReentrancy Attackのリスクが軽減する一方で、ユーザーエクスペリエンスが悪くなるというデメリットはあります。
通常であれば、1つのトランザクションで済んだ所を、Etherの受け取りを行うためにもう1つトランザクションを実行しなくてはいけないからです。

Pull Paymentはそのユーザーエクスペリエンスの悪さから利用されるケースはあまり見ません。
具体的な実装は、OpenZeppelin Contractsの`PullPayment`コントラクトがあります（[参考](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.1/contracts/security/PullPayment.sol)）。
ちなみに、`PullPayment`コントラクトはOpenZeppelin Contracts v5.0で削除される予定です（[参考](https://github.com/OpenZeppelin/openzeppelin-contracts/pull/4258)）。

## Reentrancy Attackの類型

Reentrancy Attackには、最初に呼び出される関数と、その関数の呼び出し中に呼び出される関数がどのような関係にあるかによって、大きく3つに分類されます。

- Single-Function Reentrancy Attack: 単一の関数を2回以上入れ子に呼び出す
- Cross-Function Reentrancy Attack: 同じ状態を共有する異なる関数を入れ子に呼び出す
- Cross-Contract Reentrancy Attack: 同じ状態を共有する異なるコントラクトの関数を入れ子に呼び出す

また、別の分類として、クロスチェーンでのメッセージパッシングを利用する場合のReentrancy AttackをCross-Chain Reentrancy Attackと呼ぶことがあります。
あくまで別の分類なので、Cross-Chain Reentrancy AttackかつCross-Function Reentrancy Attackである攻撃は成り立ちます。

さらに、reentrantされる関数が`view`関数である場合のReentrancy Attackを、Read-Only Reentrancy Attackと呼ぶことがあります。
これも別の分類なので、Read-Only Reentrancy AttackかつCross-Contract Reentrancy Attackである攻撃は成り立ちます。

以降、これら5つの種類のReentrancy Attackについて紹介します。

### Single-Function Reentrancy Attack

まず、Single-Function Reentrancy Attackとは、冒頭の例の`Vault`コントラクトに対して行った攻撃のように、ある単一の関数を2回以上入れ子に呼び出すReentrancy Attackのことです。
詳細は冒頭で説明した通りですので、割愛します。

#### 演習

最初の演習とは異なり、`Vault`コントラクトが初期状態で10000 ether所持しています。全てのEtherを奪取してください。
10000回ループを回すわけにはいかないので、効率良く攻撃する必要があります。

以下のコマンドを実行して、テストがパスしたら成功です。

```
forge test -vvv --match-path course/reentrancy/challenge-single-function-10000/Challenge.t.sol
```

### Cross-Function Reentrancy Attack

Cross-Function Reentrancy Attackとは、同一の関数を入れ子に呼び出すのではなく、同じ状態を共有する異なる関数を入れ子に呼び出すReentrancy Attackのことです。

例えば、以下のような`Vault`コントラクトを考えてみます。

```solidity
contract Vault is ReentrancyGuard {
    mapping(address => uint256) public balanceOf;

    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
    }

    function transfer(address to, uint256 amount) public {
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
    }

    function withdrawAll() public nonReentrant {
        require(balanceOf[msg.sender] > 0);
        (bool success,) = msg.sender.call{value: balanceOf[msg.sender]}("");
        require(success);
        balanceOf[msg.sender] = 0;
    }
}
```

Single-Function Reentrancy Attackで扱った`Vault`コントラクトと似ていますが、違いが2つあります。

まず、1つ目は、`withdrawAll`関数に`ReentrancyGuard`が適用されていることです。
これにより、`withdrawAll`関数の呼び出し中に再度`withdrawAll`関数を呼び出すことができなくなっています。

そして、2つ目は、`transfer`関数が新たに導入されたことです。
この`transfer`関数には`ReentrancyGuard`が適用されていません。

さて、この`Vault`関数は`withdrawAll`関数を再度呼び出すSingle-Function Reentrancy Attackはできませんが、`withdrawAll`関数の呼び出し中に`transfer`関数を呼び出すReentrancy Attackは可能です。
`withdrawAll`関数の`msg.sender.call`が実行される時点では、`balanceOf[msg.sender]`が更新されていないため、`transfer`関数で任意のアドレスに残高を送ることができます。
そのため、残高を他のアドレスに避難させることで、攻撃者はデポジットした額より大きな額を引き出すことが可能です。
このように、同じ状態（この例では`balanceOf`）を共有する異なる関数を入れ子（この例では`withdrawAll` -> `transfer`）に呼び出す攻撃をCross-Function Reentrancy Attackと呼びます。

図に表すと次のようになります。

```mermaid
sequenceDiagram
    participant Attacker
    participant Vault
    participant AttackerSub

	Attacker ->>+ Vault: deposit
	Vault -->>- Attacker: (deposit終了)
	Attacker ->>+ Vault: withdrawAll
	Vault ->>+ Attacker: 送金
	Attacker ->>+ Vault: AttackerSubに資金をtransferして
	Vault -->>- Attacker: (transfer終了)
	Attacker -->>- Vault: (送金終了)
	Vault -->>- Attacker: (withdrawAll終了)
	AttackerSub ->>+ Vault: withdrawAll
	Vault ->>+ AttackerSub: 送金
	AttackerSub -->>- Vault: (送金終了)
	Vault -->>- AttackerSub: (withdrawAll終了)
	AttackerSub ->>+ Attacker: 送金
	Attacker -->>- AttackerSub: (送金終了)
	Attacker ->>+ Vault: withdrawAll
	Vault ->>+ Attacker: 送金
	Attacker -->>- Vault: (送金終了)
	Vault -->>- Attacker: (withdrawAll終了)
```

この攻撃への対策は、Checks-Effects-Interactionsパターンに従うことです。
また、最悪従っていなくても`ReentrancyGuard`を適切に適用させていれば、この攻撃は防げます。
この例では、`transfer`に対しても`nonReentrant`モディファイアを修飾すれば、攻撃は実行できません。

#### 演習

上記の`Vault`コントラクトから全てのetherを排出してください。

以下のコマンドを実行して、テストがパスしたら成功です。

```
forge test -vvv --match-path course/reentrancy/challenge-cross-function/Challenge.t.sol
```

### Cross-Contract Reentrancy Attack

Cross-Contract Reentrancy Attackとは、同じ状態を共有する異なるコントラクトの関数を入れ子に呼び出すReentrancy Attackのことです。

例えば、次のような2つのコントラクト`VaultToken`と`Vault`を考えてみます。

```solidity
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract VaultToken is ERC20, Ownable {
    constructor() ERC20("VaultToken", "VT") {}

    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }

    function burnAccount(address account) public onlyOwner {
        _burn(account, balanceOf(account));
    }
}

contract Vault is ReentrancyGuard {
    VaultToken public vaultToken;

    constructor() {
        vaultToken = new VaultToken();
    }

    function deposit() public payable nonReentrant {
        vaultToken.mint(msg.sender, msg.value);
    }

    function withdrawAll() public nonReentrant {
        require(vaultToken.balanceOf(msg.sender) > 0);
        (bool success,) = msg.sender.call{value: vaultToken.balanceOf(msg.sender)}("");
        require(success);
        vaultToken.burnAccount(msg.sender);
    }
}
```

`VaultToken`コントラクトは独自のERC-20トークンです。
`Vault`コントラクトのコンストラクタで作成されます。
`Ownable`コントラクトによりアクセスコントロールが行われており、ownerである`Vault`コントラクトからしか`mint`関数と`burnAccount`関数を呼び出せません。
`mint`関数では、任意の額を任意のアドレスにミントでき、`burnAccount`関数で、任意のアドレスの全てのトークンをバーンできます。

次に、`Vault`コントラクトは、Etherを預かり、その預かったEtherに対して独自トークンである`VaultToken`を1:1で発行するように設計されたコントラクトです。
`deposit`関数と`withdrawAll`関数を持っています。
どちらの関数も`nonReentrant`モディファイアが修飾されています。

この構成はあくまで攻撃シナリオを説明するための最小限の構成を目指して作ったものです。
現実的に自然な設定は、この保管庫からFlash Loanなどの便利な機能が利用できるなど考えられますが、攻撃の本質には関係ありません。

さて、Cross-Function Reentrancy Attackとは異なり、`Vault`コントラクトの全ての関数に`nonReentrant`モディファイアが修飾されています。
そのため、`Vault`コントラクト内の関数を入れ子に呼び出すことはできません。
これはSingle-Function Reentrancy AttackとCross-Function Reentrancy Attackで紹介した`withdrawAll`関数とは異なっています。
Single-Function Reentrancy AttackやCross-Function Reentrancy Attackは防げていそうです。

しかし残念ながら、Cross-Contract Reentrancy Attackという別種の攻撃が可能になっています。

まず、依然として`withdrawAll`関数はChecks-Effects-Interactionsパターンに従っていません。
これにより、`msg.sender.call`実行中に`VaultToken`コントラクトの関数を呼び出すことが可能です。
また、`withdrawAll`関数は`balanceOf`という状態を利用しています。
そのため、これら性質を悪用して、`Vault`コントラクトに`balanceOf`の値に不整合を引き起こすことができます。

例えば、`withdrawAll`関数の`msg.sender.call`コールを受け取ったら、`VaultToken`コントラクトの`transfer`関数を呼び出すことを考えてみてください。
Cross-Function Reentrancy Attackの例と同じように、`withdrawAll`関数の`msg.sender.call`が実行される時点では、`balanceOf[msg.sender]`が更新されていないため、`VaultToken`コントラクトの`transfer`関数で任意のアドレスに残高を送ることができます。
そして、残高を他のアドレスに避難させることで、攻撃者はデポジットした額より大きな額を引き出すことが可能です。

図に表すと次のようになります。

```mermaid
sequenceDiagram
    participant Attacker
    participant Vault
    participant VaultToken
    participant AttackerSub

	Attacker ->>+ Vault: deposit
	Vault ->>+ VaultToken: mint
	VaultToken -->>- Vault: (mint終了)
	Vault -->>- Attacker: (deposit終了)
	Attacker ->>+ Vault: withdrawAll
	Vault ->>+ Attacker: 送金
	Attacker ->>+ VaultToken: AttackerSubに資金をtransferして
	VaultToken -->>- Attacker: (transfer終了)
	Attacker -->>- Vault: (送金終了)
	Vault ->>+ VaultToken: burnAccount
	VaultToken -->>- Vault: (burnAccount終了)
	Vault -->>- Attacker: (withdrawAll終了)
	AttackerSub ->>+ Vault: withdrawAll
	Vault ->>+ AttackerSub: 送金
	AttackerSub -->>- Vault: (送金終了)
	Vault ->>+ VaultToken: burnAccount
	VaultToken -->>- Vault: (burnAccount終了)
	Vault -->>- AttackerSub: (withdrawAll終了)
	AttackerSub ->>+ Attacker: 送金
	Attacker -->>- AttackerSub: (送金終了)
	Attacker ->>+ Vault: withdrawAll
	Vault ->>+ Attacker: 送金
	Attacker -->>- Vault: (送金終了)
	Vault -->>- Attacker: (withdrawAll終了)
```

以上のように、Reentrancy Guardを適用するだけではReentrancy Attackの対策として不十分であるケースが多々あります。
ただ無思考にReentrancy Guardを適用していれば、Reentrancy Attackを防げると考えてはいけないということです。
今回の攻撃は、Checks-Effects-Interactionsパターンに従えば防げます。
Effectである`vaultToken.burnAccount(msg.sender)`をInteractionである`msg.sender.call`の前に配置することです。
あくまでReentrancy Attackへの本質的な対策はChecks-Effects-Interactionsパターンに徹底的に従うことであり、Reentrancy Guardは保険程度に考えておくのが良いです。

#### 演習

`reentrancy/challenge-cross-contract`ディレクトリの`Challenge.t.sol`を完成させて、上記の`Vault`コントラクトから全てのetherを排出してください。

以下のコマンドを実行して、テストがパスしたら成功です。

```
forge test -vvv --match-path course/reentrancy/challenge-cross-contract/Challenge.t.sol
```


### Cross-Chain Reentrancy Attack

クロスチェーンでのメッセージパッシングを利用するReentrancy AttackをCross-Chain Reentrancy Attackと呼ぶことがあります。
そこまで一般的な用語ではないですが、たまに言及されることがあるので紹介します。

Cross-Chainとはいっても、実質的にはCross-Function Reentrancy AttackあるいはCross-Contract Reentrancy Attackです。

例えば、チェーンAからチェーンBへのトークンのtransferを行う`crossChainTransfer`関数があったとします。
`crossChainTransfer`関数では、そのトークンをバーンして、そのイベントをemitします。
そのイベントが検知されるとチェーンBでトークンがミントされるとします。
このようにクロスチェーンパッシングが実装されているとします。

この`crossChainTransfer`関数にreentrantができてしまい、トークンが二重に発行されるなどの状態の不整合が起きた場合、その攻撃をCross-Chain Reentrancy Attackと呼びます。
結局reentrantする元の関数が`crossChainTransfer`関数と同じコントラクトにあるならば、それは単なるCross-Function Reentrancy Attackですし、Reentrancy Guardで防ぐことができます。
また、別のコントラクトにあるならば、それはCross-Contract Reentrancy Attackですし、Checks-Effects-Interactionsパターンを遵守していれば防ぐことができます。

### Read-Only Reentrancy Attack

Read-Only Reentrancy Attackとは、reentrantされる関数がview関数、すなわち、状態がread-onlyである場合のReentrancy Attackです。

なぜわざわざRead-Only Reentrancy Attackという名前が与えられて議論されているかというと、次の2点から脆弱性が見逃されやすいことにあります。
- view関数はReentrancy Guardが適用できない
- 被害を受けるコントラクトが別の分散型アプリケーションのものであるという傾向がある

まず、view関数はReentrancy Guardが適用できないことについて説明します。

そもそもview関数は状態の変更を行いません。
ここでReentrancy Guardの`nonReentrant`モディファイアを思い出してください。
`nonReentrant`モディファイアは関数実行中かどうかのフラグを管理してチェックすることによりreentrantを防ぐという仕組みでした。
そのため、view関数にはフラグの管理のために状態の変更を行う`nonReentrant`モディファイアを当然修飾できません。
（厳密には、フラグが立っているかどうかをチェックすることだけはできます。）

また、パブリック変数のゲッターはview関数として振る舞います。
このゲッターに対しても当然Reentrancy Guardで保護できません。

つまり、コントラクトの関数にしっかりとReentrancy Guardを適用して万全だ！と思っていも、実はview関数は無防備のままでreentrantができてしまい、状態の不整合が起こせたというケースがあるのです。

次に、被害を受けるコントラクトは別の分散型アプリケーションのものであるという傾向があることについてです。

例えば、ある取引所コントラクトにRead-Only Reentrancyがあり、その取引所の価格オラクルに状態の不整合が起こせたとしましょう。
価格オラクルは基本的に外部のアプリケーションのコントラクトが参照するものなので、これだけだと、その取引所に対して攻撃を行うことはなかなかできません。

しかし、その価格オラクルを参照する別の分散型アプリケーション（レンディングプロトコルなど）は、被害を受ける可能性があります。
そのため、価格オラクルを参照する側が、価格オラクルを提供する側のコントラクトの脆弱性を知っておいて対策する必要があるのです。

この対策をあらかじめしておくのはなかなか難しいです。
取引所コントラクトのRead-Only Reentrancyが有名な事実（仕様かもしれない）であれば、開発時や監査時で対応できますが、有名でなかったら見逃されますし、そもそも発見されていなかったら監査時に見つけることも難しいです（監査では、利用する他の分散型アプリケーションのコードは監査対象外であることがほとんど）。

利用する他の分散型アプリケーションと組み合わせたときの脆弱性について考えなくてはいけないことは、Read-Only Reentrancy Attackに限らず、Cross-Contract Reentrancy Attackでも同様でした。
実際に起こるRead-Only Reentrancy Attackは基本的にCross-Contract Reentrancy Attackでもあります。
細かい話ですが、先程説明したCross-Contract Reentrancy Attackは被害を受けるコントラクト側が原因（Check-Effects-Interactionsパターンに従っていない）がありましたが、今回説明したRead-Only Reentrancy Attackでは被害を受けないコントラクト（利用されるコントラクト）側に原因（Check-Effects-Interactionsパターンに従っていない）という関係にあります。

以上の理由から、Read-Only Reentrancy Attackが個別に議論されることがあります。
そして、このRead-Only Reentrancy Attackも他のReentrancy Attackと同様にChecks-Effects-Interactionsパターンを遵守していれば防ぐことができます。

#### 演習

`reentrancy/challenge-read-only`ディレクトリの`Challenge.t.sol`を完成させて、2匹のうさぎ（`Rabbit`コントラクト）を捕まえてください。

以下のコマンドを実行して、テストがパスしたら成功です。

```
forge test -vvv --match-path course/reentrancy/challenge-read-only/Challenge.t.sol
```

## 発展: Transient Storage Opcodes (`TLOAD`/`TSTORE`)

現在Reentrancy Guardを導入すると、ガスコストが高いストレージ変数が一つ使用されてしまいます。
ストレージを使用しなければいけない理由は、スタックとメモリが実行フレーム間で共有されないからです。
将来的に、EVMに[EIP-1153: Transient storage opcodes](https://eips.ethereum.org/EIPS/eip-1153)の`TLOAD`/`TSTORE`がハードフォークによって導入される可能性があり、ガスコストが改善されることが期待されています。

`TLOAD`/`TSTORE`は、`SLOAD`/`SSTORE`と同じような振る舞いをしますが、トランザクション終了時に全て破棄されます。
トランザクション時に一時的に（transientに）使用することから、その頭文字のTを取って、`TLOAD`/`TSTORE`と呼ばれます。

ガスコストは、`TSTORE`を使えば`SSTORE`のwarm時（つまり値が非`0`の時）と同じ100 gas、`TLOAD`を使えば`SLOAD`のwarm時（つまり一度読み込まれている時）と同じ100 gasになります。
これらの値はそれぞれのcold時である22100 gas/2100 gasと比べると非常に安価です。

`TLOAD`/`TSTORE`が導入されることで、コンパイラレベルでReentrancy Guardが導入されることも検討されています。
例えば、Solidityであれば、現在はOpenZeppelinの外部コントラクトを使用することが多いですが、Solidityが公式に同等の保護を行う`transient`モディファイアを導入することも可能になります。

## 参考: Reentrancy Attackを利用するCTFの問題

https://github.com/minaminao/ctf-blockchain#reentrancy-attacks を参考にしてください。