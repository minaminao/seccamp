# EVM Assembly Programming with Huff

このページでは、HuffでEVMの命令を直接記述することでコントラクトを開発します。
安全なコントラクトを開発する上で、EVMの命令に精通することは重要です。

**目次**
- [Huffについて](#huffについて)
  - [Huffとは](#huffとは)
  - [Huffの用途](#huffの用途)
  - [Huffのインストール](#huffのインストール)
- [Ethereum Virtual Machineについて](#ethereum-virtual-machineについて)
  - [Ethereum Virtual Machineとは](#ethereum-virtual-machineとは)
  - [EVMバイトコード](#evmバイトコード)
  - [ストレージ、メモリ、スタック](#ストレージメモリスタック)
- [Huffでコントラクトを書く](#huffでコントラクトを書く)
  - [例: HuffでEthernautのMagicNumberを解く](#例-huffでethernautのmagicnumberを解く)
  - [演習: 7バイトのMagicNumberソルバー](#演習-7バイトのmagicnumberソルバー)
  - [演習: 偶数判定器](#演習-偶数判定器)
  - [演習: EVM Quine](#演習-evm-quine)
  - [演習: EVM Quine Hard](#演習-evm-quine-hard)

## Huffについて

### Huffとは

[Huff](https://huff.sh/)とは、EVM命令（`PUSH1`や`MSTORE`など）レベルでコントラクトを開発できるプログラミング言語です。
Solidityコントラクト内部でよく使われるYul言語に近いですが、Yulよりも低いレイヤーでの細かな操作ができます。

### Huffの用途

Huffの用途の一つに、ガスの最適化があります。
ほぼ全てのケースで理論上最低のガス消費量を実現できます。
そのため、様々なコントラクトで頻繁に使われる基礎的なコントラクトやライブラリをHuffで記述する取り組み（[huff-language/huffmate](https://github.com/huff-language/huffmate)）があります。

もう一つの用途として、EVMの仕様を学ぶために使えます。
コントラクト開発において、そのコントラクトがどのようなEVMバイトコードにコンパイルされ、どのような状態遷移を行うかを意識することは、セキュリティ観点から大事です。

### Huffのインストール

https://docs.huff.sh/get-started/installing/ に従ってください。

## Ethereum Virtual Machineについて

### Ethereum Virtual Machineとは

EthereumのスマートコントラクトはEthereum Virtual Machine (EVM)と呼ばれる仮想マシン上で実行されます。
EVMはオペコードが150個弱あり、オペランド数あるいはオペランド長が異なるだけのオペコードを同一視すると80個もありません。

### EVMバイトコード

EVMバイトコードとは、その名の通りEVMで実行できるコードのことです。
Solidityコンパイラは、SolidityコードをEVMバイトコードに変換しています。

例えば、`forge init`して作成される下記の`Counter`コントラクトのEVMのバイトコードを見てみましょう。

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Counter {
    uint256 public number;

    function setNumber(uint256 newNumber) public {
        number = newNumber;
    }

    function increment() public {
        number++;
    }
}
```

`forge init`したディレクトリで、`forge build`を実行するとコンパイルが行われ、`out`ディレクトリにABI、バイトコード、メタデータ、抽象構文木などのコンパイル結果が出力されます。

`Counter`コントラクトのデータは、`out/Counter.sol/Counter.json`にあります。
バイトコード部分だけ抜粋すると次のデータが載っています。

```json
  "bytecode": {
    "object": "0x608060405234801561001057600080fd5b5060f78061001f6000396000f3fe6080604052348015600f57600080fd5b5060043610603c5760003560e01c80633fb5c1cb1460415780638381f58a146053578063d09de08a14606d575b600080fd5b6051604c3660046083565b600055565b005b605b60005481565b60405190815260200160405180910390f35b6051600080549080607c83609b565b9190505550565b600060208284031215609457600080fd5b5035919050565b60006001820160ba57634e487b7160e01b600052601160045260246000fd5b506001019056fea2646970667358221220fae0b1cefc14f831678071dac56d7c756dba4a7e705742be3f473c8c85e2769564736f6c63430008140033",
    "sourceMap": "65:192:19:-:0;;;;;;;;;;;;;;;;;;;",
    "linkReferences": {}
  },
  "deployedBytecode": {
    "object": "0x6080604052348015600f57600080fd5b5060043610603c5760003560e01c80633fb5c1cb1460415780638381f58a146053578063d09de08a14606d575b600080fd5b6051604c3660046083565b600055565b005b605b60005481565b60405190815260200160405180910390f35b6051600080549080607c83609b565b9190505550565b600060208284031215609457600080fd5b5035919050565b60006001820160ba57634e487b7160e01b600052601160045260246000fd5b506001019056fea2646970667358221220fae0b1cefc14f831678071dac56d7c756dba4a7e705742be3f473c8c85e2769564736f6c63430008140033",
    "sourceMap": "65:192:19:-:0;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;116:80;;;;;;:::i;:::-;171:6;:18;116:80;;;88:21;;;;;;;;;345:25:21;;;333:2;318:18;88:21:19;;;;;;;202:53;;240:6;:8;;;:6;:8;;;:::i;:::-;;;;;;202:53::o;14:180:21:-;73:6;126:2;114:9;105:7;101:23;97:32;94:52;;;142:1;139;132:12;94:52;-1:-1:-1;165:23:21;;14:180;-1:-1:-1;14:180:21:o;381:232::-;420:3;441:17;;;438:140;;500:10;495:3;491:20;488:1;481:31;535:4;532:1;525:15;563:4;560:1;553:15;438:140;-1:-1:-1;605:1:21;594:13;;381:232::o",
    "linkReferences": {}
  },
```

`bytecode`と`deployedBytecode`の`object`フィールドにあるデータがバイトコードです。

バイトコードが2つありますが、この違いは`bytecode`がデプロイ時のバイトコードで、`deployedBytecode`が実行時のバイトコードであることです。

Yellow Paperに準拠すれば、トランザクションには`to`フィールドと`init`フィールドがあります。
トランザクションの受信者である`to`フィールドが空であるとき、`init`フィールドに指定されたバイト列が実行されます。
ただし、Gethなどの実際のクライアントは`data`フィールドが`init`フィールドを兼任していることがあります。
以降、`data`フィールドに統一します。

`to`フィールドが空であるとき、`data`フィールドに`bytecode`が実行されて、`Counter`コントラクトのための新しいアドレスが割り当てられ、そのアドレスにコントラクトがデプロイされます。

この中身についての解説は「[Reversing EVM Bytecodes](../reversing-evm)」で行います。

### ストレージ、メモリ、スタック

EVMにおいて、データを保存できる領域が3つあります。
ストレージ、メモリ、スタックです。
EVMバイトコードを読み書きする上で、この3つの領域の性質を正確に把握することは重要です。
ここでは、簡単に概要を説明します。

ストレージは、コントラクトごとに用意される永続的なデータ領域であり、32バイトのスロットから32バイトの値へのマッピングです。
初期状態では全ての値が`0`になっています。
`SELFDESTRUCT`命令が実行されると破壊されます。
ストレージは他のコントラクトから直接読み書きできません。
`SLOAD`命令で読み取り、`SSTORE`命令で書き込みができます。

メモリは、コールごとに用意される一時的なデータ領域であり、任意の位置に読み書きができる連続的なものです。
初期状態ではサイズ`0`となっています。
コールが終了すると、メモリも破棄されます。
任意の位置に読み書きできますが、インデックスが大きければ大きいほど二次関数的にガスコストが増加します。
`MLOAD`命令で読み取り、`MSTORE`命令で書き込みができます。

スタックは、コールごとに用意される一時的なデータ領域であり、一般的なスタック構造と同様にプッシュとポップの2つの操作ができ、後にプッシュしたものが先にポップされます。
`PUSHx`命令でプッシュができ、`POP`命令でポップができます。
その他にも、`DUPx`命令で複製や、`SWAPx`命令でスタック内の要素のスワップなどができます。
コールが終了すると、スタックも破棄されます。
スタックに保管できる要素の制限は1024であり、その数を超えてプッシュしようとするとStack Too Deepと呼ばれるエラーが起き、トランザクションがリバートします。

## Huffでコントラクトを書く

### 例: HuffでEthernautのMagicNumberを解く

[EthernautのMagic Number](https://ethernaut.openzeppelin.com/level/0x2132C7bc11De7A90B87375f282d36100a29f97a9)は、`whatIsTheMeaningOfLife()`という関数呼び出しに対して、`42`という数値を返すコントラクトを作成する問題です。
ただし、コントラクトサイズが10を超えてはいけません。

まず、Solidityで`whatIsTheMeaningOfLife()`に対して`42`を返すコントラクトを書くと次のようになります。

```solidity
contract MagicNumberSolverNaive {
    function whatIsTheMeaningOfLife() public pure returns (uint256) {
        return 42;
    }
}
```

このコントラクトのバイトコードは、次のようになります。

```
$ solc course/evm-with-huff/challenge-magic-number/MagicNumberSolverNaive.sol --bin-runtime --optimize --no-cbor-metadata

======= course/evm-with-huff/challenge-magic-number/MagicNumberSolverNaive.sol:MagicNumberSolverNaive =======
Binary of the runtime part:
6080604052348015600e575f80fd5b50600436106026575f3560e01c8063650500c114602a575b5f80fd5b602a60405190815260200160405180910390f3
```

`solc`はデフォルトで、コントラクトのバイトコードにCBORメタデータを付加するので、`--no-cbor-metadata`オプションを指定することで削除しています。
このメタデータについては、Solidityドキュメントの「[バイトコードにおけるメタデータハッシュのエンコーディング](https://solidity-ja.readthedocs.io/ja/latest/metadata.html#encoding-of-the-metadata-hash-in-the-bytecode)」に詳しく書いてあります。

出力されたコントラクトのバイトコードのサイズを調べると62バイトであり、条件の`10`を満たすには程遠いです。
そのため、条件を満たすコントラクトを作るには、EVM命令を直接記述する必要がありそうです。

SolidityにはYulというEVM命令にかなり近い記述ができる言語がありますが、HuffはEVM命令を直接記述できます。
そのHuffで今回の条件を満たすコントラクトを書くと次のようになります。

```js
#define macro MAIN() = takes (0) returns (0) {
    0x2a    // [0x2a]
    0x00    // [0x00, 0x2a]
    mstore  // []
    0x20    // [0x20]
    0x00    // [0x00, 0x20]
    return  // []
}
```

まず、`#define macro MAIN() = takes (0) returns (0) {`と`}`については一旦置いといて、これに囲まれた部分が実行されるイメージを持ってください。

Huffでは命令を1行ずつ書く慣習があります。
`0x2a`は`PUSH1 0x2a`を表します。
`// [0x2a]`はコメントであり、`PUSH1 0x2a`を実行後にスタックが`[0x2a]`になることを表しています。
このスタックのコメントも、スタックの中身と遷移が自明でない限り記述するのが慣習です。

次に`0x00`があります。
`0x00`は`PUSH0`を表します。
`PUSH0`は2023年4月の`Shanghai`アップグレードによって導入されたオペコードです。
そのため、以前のHuffでは`PUSH1 0x00`を表していました。
新しい値がプッシュされたら左に値を追加するのが慣習で、コメントは`[0x00, 0x2a]`になります。

続く`mstore`命令は、`offset`と`value`の2つの引数をスタックから順にポップして受け取り、メモリの`[offset,offset+32)`の位置に`value`をストアする命令です。
現在のスタックが`[0x00, 0x2a]`なので、`0x00`の位置に`0x2a`が32バイトの値としてストアされ、メモリは次のようになります。

```
0x00: 000000000000000000000000000000000000000000000000000000000000002a
```

同様に、`PUSH1 0x20` と`PUSH0`が処理されて、スタックが`[0x00, 0x20]`になります。

最後に、`return`命令が実行されます。
`return`命令は、`offset`と`size`の2つの引数をスタックから順にポップして受け取り、メモリの`[offset,offset+size)`の位置のデータを呼び出し側に返します。
スタックが`[0x00, 0x20]`なので、返るデータは`000000000000000000000000000000000000000000000000000000000000002a`になり、`42`という数値が正しく返っていることがわかります。

上記のHuffコードをコンパイルして、コントラクトのバイトコードを取得してみます。

```
$ huffc -r course/evm-with-huff/challenge-magic-number/MagicNumberSolver.huff 
⠙ Compiling... 
602a5f5260205ff3⏎ 
```

出力された`602a5f5260205ff3`は8バイトです。
これで、MagicNumberが解けたことになります。
Solidityで書いた最適化を行ったコントラクトが62バイトだったので、およそ1/8ほどのバイト長になったことがわかります。
バイト長が小さくなると、デプロイ時のガスコストが低下しますが、それだけでなく実行時のコストも低下しています。

上記のように、Huffでは`PUSH`命令以外の全ての命令は、ニーモニックをそのまま記述すれば良いです。
`PUSH`命令のみニーモニックを書くのではなく、プッシュする値を記述します。

以下、演習です。
演習では以上で説明したHuffの機能以外に使用しませんが、他にも[様々な機能](https://docs.huff.sh/get-started/huff-by-example/)があります。

### 演習: 7バイトのMagicNumberソルバー

上記のコントラクト（以下再掲）のバイトコードは8バイトです。

```js
#define macro MAIN() = takes (0) returns (0) {
    0x2a    // [0x2a]
    0x00    // [0x00, 0x2a]
    mstore  // []
    0x20    // [0x20]
    0x00    // [0x00, 0x20]
    return  // []
}
```

このコントラクトのサイズを1バイト小さくしてください。
`MagicNumberSolver.huff`を書き換えてください。
この演習はEVMへの理解を深めるための問題なので、[evm.codes](https://www.evm.codes/?fork=shanghai)を参考にして解くことを推奨します。

以下のコマンドを実行して、テストがパスしたらクリアです。

```
forge test --match-path course/evm-with-huff/challenge-magic-number/MagicNumberSolver.t.sol --match-test test7Bytes -vvv
```

<details>
<summary>ヒント1</summary>

この6つの命令のうち、どれか1つを別の命令に変える必要があります。

</details>

<details>
<summary>ヒント2</summary>

`PUSH1 0x20`を他の命令に置き換えられないでしょうか？

</details>

### 演習: 偶数判定器

偶数を判定するコントラクトをHuffで記述してください。
より正確には、コールデータに与えられる32バイトの数値が偶数ならば`1`を、奇数ならば`0`を返してください。
コントラクトサイズは11以下にしてください。

以下のコマンドを実行して、テストがパスしたらクリアです。

```
forge test --match-path course/evm-with-huff/challenge-even/EvenSolver.t.sol -vvv
```

### 演習: EVM Quine

[Quine](https://ja.wikipedia.org/wiki/%E3%82%AF%E3%83%AF%E3%82%A4%E3%83%B3_(%E3%83%97%E3%83%AD%E3%82%B0%E3%83%A9%E3%83%9F%E3%83%B3%E3%82%B0))とは、自身のソースコードと完全に同じ文字列を出力するプログラムのことです。

例えば、Pythonにおいては次のコードがQuineの一つです。

```python
a='a=%r;print(a%%a)';print(a%a)
```

実際に実行してみると、Quineであることを確認できます。

```python
>>> a='a=%r;print(a%%a)';print(a%a)
a='a=%r;print(a%%a)';print(a%a)
```

EVMにおけるQuineとして、コントラクトにコールをするとそのコントラクトのバイトコードを返すコントラクトが考えられます。
より厳密には、`0xXXYYZZ`というバイトコードがあったときに、そのバイトコードを実行すると`0xXXYYZZ`が`RETURN`命令で返るということです。

この問題では、「デプロイ時のコード」と「デプロイされたコントラクトのコード」と「そのコントラクトに`STATICCALL`命令を行ったときの返り値」が全て一致するようなEVM Quineを作成してください。
コントラクトサイズの制限はありません。

以下のコマンドを実行して、テストがパスしたらクリアです。

```
forge test --match-path course/evm-with-huff/challenge-quine/QuineSolver.t.sol -vvv
```

### 演習: EVM Quine Hard

前の問題では全ての命令が許可されていました。

この問題では、より難しくするために次の命令群の使用を禁止します。
（前の問題のネタバレにならないように隠しています。）

<details>
<summary>使用不可の命令一覧</summary>

- `0x30` ~ `0x48`
- `SLOAD`
- `SSTORE`
- `CREATE`
- `CALL`
- `CALLCODE`
- `DELEGATECALL`
- `CREATE2`
- `STATICCALL`
- `SELFDETRUCT`

</details>

また、コントラクトサイズを33以下にしてください。

以下のコマンドを実行して、テストがパスしたらクリアです。

```
forge test --match-path course/evm-with-huff/challenge-quine-hard/QuineSolver.t.sol -vvv
```
