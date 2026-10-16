<script lang="ts">
    // Bilingual -> The web frontend -> the home's background
    // Behavior 89 (Son 2026-10-16: the home looked dull): behind the home's cards, a faint
    // dotted map of Australia — one dot per 0.8° cell that holds a suburb (homeDots.ts,
    // generated from the engine's own suburbs, so the shape is the data's, not drawn by
    // hand) — where suburb points light up in turn, the cities more often. It is drawn on
    // a canvas in the accent and gold tokens and drifts slowly (a CSS animation).
    // Under prefers-reduced-motion the CSS drift is none and the canvas is drawn once,
    // still. It never takes a tap (pointer-events: none) and sits under the cards' own
    // solid surfaces. The home only: the planner and the map do not mount it.
    import { onMount } from 'svelte';
    import { DOTS, DOT_COLS, DOT_ROWS } from '$lib/homeDots';

    let canvas: HTMLCanvasElement | undefined = $state();

    // A degree of longitude is shorter than one of latitude at Australia's middle (~27°S).
    const X_SCALE = Math.cos((27 * Math.PI) / 180);
    const LIGHT_MS = 2600; // one point's glow, rise and fade
    const EVERY_MS = 500; // a new point lights this often
    const MAX_LIT = 8;

    type Lit = { i: number; t0: number; gold: boolean };

    onMount(() => {
        const c = canvas!;
        const ctx = c.getContext('2d');
        if (!ctx) return;
        const still = window.matchMedia?.('(prefers-reduced-motion: reduce)').matches ?? false;
        const n = DOTS.length / 3;
        // Lighting favours the cities: a point's chance is its weight squared.
        const pool: number[] = [];
        for (let i = 0; i < n; i++) for (let k = 0; k < DOTS[i * 3 + 2] ** 2; k++) pool.push(i);

        let w = 0, h = 0, cell = 0, ox = 0, oy = 0;
        let accent = '#0d7a63', gold = '#d4a72c';
        function measure() {
            const dpr = Math.min(window.devicePixelRatio || 1, 2);
            const r = c.getBoundingClientRect();
            w = r.width;
            h = r.height;
            c.width = Math.round(w * dpr);
            c.height = Math.round(h * dpr);
            ctx!.setTransform(dpr, 0, 0, dpr, 0, 0);
            // Fit the map in the box, a little inset; bottom-right on a wide screen (the
            // cards sit high and centred), centred on a phone.
            const mw = DOT_COLS * X_SCALE, mh = DOT_ROWS;
            cell = Math.min((w * 0.94) / mw, (h * 0.86) / mh);
            const wide = w >= 768;
            ox = wide ? w - mw * cell - w * 0.04 : (w - mw * cell) / 2;
            oy = wide ? h - mh * cell - h * 0.06 : h - mh * cell - h * 0.04;
            const cs = getComputedStyle(c);
            accent = cs.getPropertyValue('--accent').trim() || accent;
            gold = cs.getPropertyValue('--gold-mark').trim() || gold;
        }
        const px = (i: number) => ox + (DOTS[i * 3] + 0.5) * cell * X_SCALE;
        const py = (i: number) => oy + (DOTS[i * 3 + 1] + 0.5) * cell;

        let lit: Lit[] = [];
        function draw(now: number) {
            ctx!.clearRect(0, 0, w, h);
            const r0 = Math.max(0.9, cell * 0.16);
            ctx!.fillStyle = accent;
            for (let i = 0; i < n; i++) {
                const wt = DOTS[i * 3 + 2];
                ctx!.globalAlpha = 0.1 + wt * 0.06;
                ctx!.beginPath();
                ctx!.arc(px(i), py(i), r0 * (0.8 + wt * 0.2), 0, Math.PI * 2);
                ctx!.fill();
            }
            for (const l of lit) {
                const p = (now - l.t0) / LIGHT_MS; // 0..1
                if (p < 0 || p > 1) continue;
                const glow = Math.sin(p * Math.PI); // up, then down
                const col = l.gold ? gold : accent;
                ctx!.fillStyle = col;
                ctx!.globalAlpha = 0.8 * glow;
                ctx!.beginPath();
                ctx!.arc(px(l.i), py(l.i), r0 * 2.6, 0, Math.PI * 2);
                ctx!.fill();
                ctx!.strokeStyle = col;
                ctx!.lineWidth = 1.2;
                ctx!.globalAlpha = 0.5 * (1 - p);
                ctx!.beginPath();
                ctx!.arc(px(l.i), py(l.i), r0 * (2.6 + p * 10), 0, Math.PI * 2);
                ctx!.stroke();
            }
            ctx!.globalAlpha = 1;
        }

        measure();
        if (still) {
            draw(0);
            const ro = new ResizeObserver(() => (measure(), draw(0)));
            ro.observe(c);
            return () => ro.disconnect();
        }

        let raf = 0, last = 0, lastSpawn = 0;
        function frame(now: number) {
            raf = requestAnimationFrame(frame);
            if (now - last < 33) return; // ~30 fps is plenty for a slow glow
            last = now;
            lit = lit.filter((l) => now - l.t0 < LIGHT_MS);
            if (now - lastSpawn > EVERY_MS && lit.length < MAX_LIT) {
                lastSpawn = now;
                lit.push({ i: pool[Math.floor(Math.random() * pool.length)], t0: now, gold: Math.random() < 0.25 });
            }
            draw(now);
        }
        const ro = new ResizeObserver(measure);
        ro.observe(c);
        raf = requestAnimationFrame(frame);
        return () => {
            cancelAnimationFrame(raf);
            ro.disconnect();
        };
    });
</script>

<div class="home-backdrop" aria-hidden="true">
    <canvas bind:this={canvas}></canvas>
</div>

<style>
    .home-backdrop {
        position: fixed;
        inset: calc(var(--header-total) + var(--home-news-h, 0px)) 0 0 0;
        z-index: 0;
        overflow: hidden;
        pointer-events: none;
    }
    canvas {
        display: block;
        width: 100%;
        height: 100%;
        animation: home-drift 36s ease-in-out infinite alternate;
    }
    /* A slow drift and breath of the whole map, so even between lights it is alive. */
    @keyframes home-drift {
        from {
            transform: translate(0, 0) scale(1);
        }
        to {
            transform: translate(-1.5%, -1%) scale(1.04);
        }
    }
    @media (prefers-reduced-motion: reduce) {
        canvas {
            animation: none;
        }
    }
</style>
