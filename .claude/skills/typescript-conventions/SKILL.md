---
name: typescript-conventions
description: "TypeScript / JavaScript のコードを書く・レビューする・リファクタする時に使う。型定義（公開オブジェクト型は interface、ユニオン/ユーティリティ型は type）、const 優先・any 禁止（unknown + 絞り込み）、Biome 準拠（デフォルト、フォールバックは Prettier/ESLint）、import 順序（標準→外部→内部・相対パス最小化）を適用する。.ts/.tsx/.js/.jsx ファイルの編集時に発動する。"
user-invocable: true
---

# TypeScript / JavaScript 規約

TypeScript / JavaScript のコードを書く・直す・レビューするときに従う規約。整形・lint はツールに任せ、手動整形しない。

## 型定義

- **公開オブジェクト型は `interface`** を使う。
- **ユニオン型・ユーティリティ型は `type`** を使う。

```ts
// 公開する構造体は interface
interface User {
  id: string;
  name: string;
}

// ユニオン / ユーティリティは type
type Status = "active" | "archived";
type PartialUser = Partial<User>;
```

## 変数・型の安全性

- **`const` を優先**する。再代入が必要なときだけ `let`。
- **`any` は禁止**。外部入力など型が不明な値は `unknown` で受け、型の絞り込み（type guard / `typeof` / スキーマ検証）で確定させてから使う。

```ts
function parse(input: unknown): User {
  if (typeof input === "object" && input !== null && "id" in input) {
    // ここで User として扱えるよう絞り込む
  }
  throw new Error("invalid input");
}
```

## フォーマッタ / Linter

- **デフォルトは Biome**。formatter と linter を単一ツール・単一設定（`biome.json`）で兼ねる。新規プロジェクトではまず Biome を選ぶ。
- **フォールバックは Prettier（フォーマッタ）+ ESLint（Linter）**。次の場合に切り替える。
  - 既存プロジェクトが Prettier/ESLint を採用している（「既存コードに合わせる」原則を優先）。
  - フレームワーク固有の ESLint プラグインや、Biome が未対応・カバー不足の Lint ルール（高度な type-aware ルール等）が必要。
- いずれの場合も保存時整形を前提にし、手動整形しない。

## import 順序

- **標準 → 外部 → 内部** の順に並べる。
- 相対パスは最小限にする。

既存コードのスタイル・命名・イディオムを優先し、勝手に新流儀を持ち込まない。
