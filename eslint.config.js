import js from "@eslint/js";
import tseslint from "@typescript-eslint/eslint-plugin";

export default [
  { ignores: ["dist/", "tsp-output/"] },
  js.configs.recommended,
  ...tseslint.configs["flat/recommended"],
];
