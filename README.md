# 分散型アプリケーション脆弱性解析ゼミ

[セキュリティ・キャンプ全国大会2023](https://www.ipa.go.jp/jinzai/security-camp/2023/zenkoku/index.html)の『分散型アプリケーション脆弱性解析ゼミ』の紹介と講義資料を置くリポジトリです。

---

## 講義資料

随時公開します。資料の順序は適当です。

1. [Introduction to Foundry](course/foundry)
	- ゼミを通して使用する開発ツールであるFoundryの使い方を紹介し、コントラクトを作成する演習を行います。
2. [Reentrancy Attacks](course/reentrancy)
	- Reentrancy Attackの仕組みと対策、類型を紹介し、攻撃の演習を行います。
3. [Oracle Manipulation Attacks & Flash Loans](course/oracle-manipulation)
	- Oracle Manipulation Attackの仕組みと対策、Flash Loanを組み合わせた攻撃を紹介し、攻撃の演習を行います。
4. [Ethernaut with Foundry](course/ethernaut)
	- EthernautをFoundryで解く流れを紹介し、実際に解いてみてForge Scriptを利用してオンチェーンと対話する方法を学びます。
5. [EVM Assembly Programming with Huff](course/evm-with-huff)
	- Huff言語でEVMの命令を直接記述することでコントラクトを作成する方法を紹介し、その演習を行います。
6. [Reversing EVM Bytecodes](course/reversing-evm)
	- EVMバイトコードを逆アセンブルして、その結果を読み解くリバーシング技術を紹介します。
7. [Storage Collisions & Proxies](course/storage-collision)
	- Storage Collisionとプロキシの仕組みについて紹介し、攻撃の演習を行います。
8. [On-Chain Investigations of Attacks](course/attack-investigation)
	- トランザクショントレーサーなどの攻撃の調査技術について紹介します。
9. [How to Reproduce Attacks](course/reproducing-attack/)
	- 攻撃の調査結果を使用し、攻撃を再現する手法について紹介します。

---

以下、応募開始時点で公開したゼミの紹介です（エントリー期間は終了しました）。

## 概要

分散型アプリケーションの脆弱性は、ときに多額の資金流出やガバナンスの乗っ取りなど甚大な被害をもたらします。2022年だけでも約5000億円に相当する資産が分散型アプリケーションへの攻撃により失われたと報告されています。

このゼミでは、現実世界で起こった分散型アプリケーションの攻撃を解析し、その実装を行いながら、安全な分散型アプリケーションを構築するために欠かせない知識と技術を学びます。本期間の5日間（+ 事前学習期間）を通じて、攻撃者視点で実際の攻撃をテスト環境で再現することで、Ethereum, Ethereum Virtual Machine (EVM), Solidityなどの基礎知識や、分散型アプリケーションの開発・テスト・運用のスキルを身につけていきます。

分散型アプリケーションをpwnすることは（Baba is Youのような）パズルゲームを解くような楽しさを持ち合わせています。スマートコントラクトは一般的なプログラムと比べて非常にコンパクトなものです。EVMにはオペコードが150個もありませんし、オペランド数が異なるだけのオペコードを同一視すると80個もありません。これはx86-64などのISAと比べるととてもシンプルな構成です。また、Solidityの言語機能も他のプログラミング言語と比べたらかなりスッキリとしています。分散型アプリケーションは、そのような必要最低限のルールの中で構築されたステートマシンと見做せます。そのステートマシンで、熟練の開発者が意図していない挙動を見つけ出し攻撃まで繋げることは高難度パズルをクリアするような面白さがあります。

セキュリティ・キャンプ全国大会は22歳以下の方が申し込むことができます。参加費は無料ですが、人数に制約があり、ちょっとした応募課題を解いてもらう必要があります。具体的な応募要項については、セキュリティ・キャンプ全国大会の公式ページを参照してください。

## やること

参加者の目標は「過去発生した分散型アプリケーションの攻撃のうち一つ選び、その理論の理解とエクスプロイトの構築・実装を行うこと」です。講師はその手助けをします。

昨年の参加者は、2022年7月23日に発生した[Audius Protocolのエクスプロイト](https://blog.audius.co/article/audius-governance-takeover-post-mortem-7-23-22)（ストレージの衝突に起因する任意コード実行）を実装しました。セキュリティ・キャンプ全国大会が8月8日〜8月12日に開催されたので、当時は2週間前に発生した攻撃を解析し、そのエクスプロイトを実装したことになります。また、実際に攻撃者が行った手法では、ガバナンスへのプロポーザルが必要でしたが、参加者自身がそれを省略して単一トランザクションで効率的に攻撃する手法を考えてくれました。最後に、攻撃されたばかりで情報が世にあまり出ていなかったため、それらをGitHubのリポジトリにまとめて[Immunefi](https://immunefi.com/)のコミュニティに簡単に共有しました。攻撃概要と実装については[参加者のリポジトリ](https://github.com/nukanoto/audius-exploit)を参照してください。

何も準備せずに本期間（今年は8月7日〜8月11日）で実装するのは困難だと思いますので、6月中旬から7月末までに、事前学習として週1程度で講義を行う予定です。講義内容は参加者の要望に応じて柔軟に決めたいと思います。昨年は、[Uniswap V2](https://github.com/Uniswap/v2-core)のコードリーディングと[Harvest Financeのエクスプロイト](https://medium.com/harvest-finance/harvest-flashloan-economic-attack-post-mortem-3cf900d65217)（Flash Loanによるオラクル操作）の実装を行いました。また、自学として[Ethernaut](https://ethernaut.openzeppelin.com/)の問題を解いてくれました（[参加者の実装](https://github.com/nukanoto/ethernaut/tree/main/src)）。

どのような攻撃を選択するかは参加者の自由です。王道のテクニックを使ったものでもいいですし、変わり種でも良いです。7月末までに決まっていればOKです。本期間でギリギリ実装できそうな難易度で、面白い攻撃を選べると非常に良いと思います。

EVM系の攻撃を扱うことを想定していますが、希望があればEVM系の攻撃でなくても大丈夫です。ただし、チェーン自体への攻撃は範囲外とします。例えば、次のようなものも範囲に含まれます。
- 非EVM系チェーンのアプリケーションへの攻撃（Solana, Move系など）
- クロスチェーンアプリケーションへの攻撃（EVM <> 非EVMなど）
- クロスレイヤーアプリケーションへの攻撃（Layer1 <> Layer2など）
- ミドルウェアレイヤーを利用する攻撃（MEVなど）
- ゼロ知識証明アプリケーションへの攻撃

## 応募

応募のエントリーの〆切は5月15日で、応募課題の〆切が5月22日です。エントリーがまず先で、エントリー自体は簡単にできるので、現時点で参加してみようかなと思った方は、とりあえず[ここ](https://www.ipa.go.jp/jinzai/security-camp/2023/zenkoku/vote.html)からエントリーしてもらえると（人数把握など出来て）嬉しいです。

応募お待ちしております！

最後に、応募課題を解くのに役立つかもしれない資料を置いておきます。
- https://twitter.com/BlockSecTeam: 攻撃情報つぶやいてくれる。
- https://twitter.com/peckshield: 攻撃情報つぶやいてくれる2。
- https://rekt.news/leaderboard/: 過去攻撃された有名プロトコル一覧（被害額順）。
- https://github.com/SunWeb3Sec/DeFiHackLabs: DeFiのインシデント集（PoCの質はピンキリ）。
- https://github.com/minaminao/ctf-blockchain: CTFのブロックチェーン問とWriteup集。
- https://solidity-ja.readthedocs.io/: Solidityのドキュメント（日本語）。
- https://github.com/foundry-rs/foundry: おすすめ開発環境。ゼミで利用します。
- https://phalcon.xyz/: BlockSecのトランザクションビューア。
- https://library.dedaub.com/: Dedaubのコントラクトビューア。
- https://www.evm.codes/: EVMオペコード一覧。
- https://github.com/huff-language: EVM命令を直接書く言語。人間コンパイラになってみたい人におすすめ。
