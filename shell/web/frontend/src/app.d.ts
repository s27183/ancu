// See https://svelte.dev/docs/kit/types#app.d.ts
declare global {
    namespace App {
        // interface Error {}
        // interface Locals {}
        // interface PageData {}
        // interface PageState {}
        // interface Platform {}
    }
}

// Build-time env (Vite statically replaces `import.meta.env.VITE_*`; unset → undefined).
interface ImportMetaEnv {
    // Optional Protomaps basemap pmtiles archive URL (8-S2d, map-stack.md §2). Unset →
    // the no-basemap minimalStyle fallback. Dev/eval: a Protomaps daily build URL.
    // Prod: the owned AU extract on R2 (deploy-build).
    readonly VITE_PMTILES_URL?: string;
}
interface ImportMeta {
    readonly env: ImportMetaEnv;
}

export {};
