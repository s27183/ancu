<script lang="ts">
    // Bilingual -> the bilingual plan reaches the phone it is read on -> the web frontend ->
    // the «Use as an app» pill and its sheet (behavior 153; the rule and its block:
    // installHint.ts). The pill sits at the right of the home's top row, opposite the
    // Introduction pill; its sheet gives this device's steps and a clip of the install
    // (muted, inline, looping, with controls). Two pills, iPhone and Android, pick the clip;
    // the sheet opens on the one installClip names for this device: Android on an Android
    // phone, iPhone otherwise (behavior 158). The pills sit above the steps and pick them
    // too; the button and the in-app line show only on the visitor's own phone's pill; a
    // computer keeps its own steps on top and the phone steps under «On your phone»
    // (behavior 159; the rule: sheetView). A clip whose file fails fires the video's
    // error: its player is dropped and the pills stay, so the sheet never shows a broken
    // player. The iPhone clip is cropped to 540×1000, above the phone's dock, so no frame
    // shows the apps pinned on Son's own phone (behavior 156); the player takes each clip's
    // own aspect (--ar), its height capped at 60vh, so a tall clip has no bars beside it.
    // Where the browser offers an install (Chrome, Edge: caught in app.html as
    // window.__ancuInstall), the sheet puts a one-tap Install button above the steps; the
    // tap opens the browser's own dialog. Install says so in the sheet and drops the pill;
    // Cancel drops the button for the rest of the page load: Chrome for Android makes a new
    // offer at once after a dismissal (seen on the Pixel 9 Pro emulator), and the visitor has
    // just said no; the menu steps stay (behavior 157).
    import { onMount } from 'svelte';
    import { t } from '$lib/i18n';
    import Modal from '$lib/Modal.svelte';
    import { browserHintEnv, INSTALL_VIDEOS, installClip, installSteps, sheetView, type InstallClip, type InstallSteps, type OfferState } from '$lib/installHint';

    let steps = $state<InstallSteps | null>(null);
    let clip = $state<InstallClip>('ios');
    const video = $derived(INSTALL_VIDEOS[clip]);
    const CLIPS: [InstallClip, string][] = [
        ['ios', 'iPhone'],
        ['android', 'Android']
    ];
    let open = $state(false);
    let failed = $state<Record<InstallClip, boolean>>({ ios: false, android: false });
    let videoReady = $state(false);
    let offerState = $state<OfferState>('none');
    let installed = $state(false);
    // Behavior 159: pulses as the «Giới thiệu» pill does, every page view until tapped.
    let pulse = $state(true);
    const view = $derived(steps ? sheetView(steps, clip, offerState) : null);
    let declined = false;

    interface InstallOffer extends Event {
        prompt(): Promise<void>;
        userChoice: Promise<{ outcome: 'accepted' | 'dismissed' }>;
    }
    type Held = { offer: InstallOffer | null; installed: boolean };
    const held = (): Held | undefined => (window as Window & { __ancuInstall?: Held }).__ancuInstall;

    function readOffer() {
        const h = held();
        if (h?.installed) installed = true;
        offerState = declined ? 'used' : h?.offer ? 'held' : offerState === 'held' ? 'used' : offerState;
    }

    onMount(() => {
        steps = installSteps(browserHintEnv());
        readOffer();
        window.addEventListener('ancu-install', readOffer);
        return () => window.removeEventListener('ancu-install', readOffer);
    });

    async function install() {
        const h = held();
        const offer = h?.offer;
        if (!h || !offer) return;
        h.offer = null;
        offerState = 'used';
        try {
            await offer.prompt();
        } catch {
            // The browser refused to open the dialog (no tap reached it): keep the offer.
            h.offer = offer;
            offerState = 'held';
            return;
        }
        if ((await offer.userChoice).outcome === 'accepted') installed = true;
        else declined = true;
        readOffer();
    }

    function show() {
        pulse = false;
        clip = installClip(steps) ?? 'ios';
        failed = { ios: false, android: false };
        videoReady = false;
        open = true;
    }

    function pick(c: InstallClip) {
        if (c === clip) return;
        videoReady = false;
        clip = c;
    }
</script>

{#if steps && !installed}
    <button type="button" class="home-pill install-pill pill-pulse" class:pulse onclick={show} aria-haspopup="dialog">
        <span class="install-pill-ico" aria-hidden="true">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"
                ><rect x="6" y="2.5" width="12" height="19" rx="2.5" /><line x1="12" y1="8.5" x2="12" y2="14.5" /><line x1="9" y1="11.5" x2="15" y2="11.5" /></svg
            >
        </span>
        <span>{$t('installhint.pill')}</span>
    </button>
{/if}
{#if steps && open}
    <Modal title={$t('installhint.label')} onClose={() => (open = false)}>
        <div class="install-sheet">
            {#if installed}
                <p class="install-done" role="status">{$t('installhint.installed')}</p>
            {:else}
                {#if view?.desktop}
                    {#if view.button}
                        <button type="button" class="btn btn-primary install-now" onclick={install}>{$t('installhint.install')}</button>
                    {/if}
                    <ol class="install-steps">
                        {#each ['1', '2'] as const as k (k)}
                            <li>{$t(`installhint.desktop.${k}`)}</li>
                        {/each}
                    </ol>
                    <p class="install-phone">{$t('installhint.phone')}</p>
                {/if}
                <div class="lang clip-pick" data-active={clip} role="group" aria-label={$t('installhint.video')}>
                    <span class="lang-thumb" aria-hidden="true"></span>
                    {#each CLIPS as [c, name] (c)}
                        <button type="button" class:active={clip === c} aria-pressed={clip === c} onclick={() => pick(c)}>{name}</button>
                    {/each}
                </div>
                {#if view && !view.desktop && view.button}
                    <button type="button" class="btn btn-primary install-now" onclick={install}>{$t('installhint.install')}</button>
                {/if}
                <ol class="install-steps">
                    {#if view?.inApp}
                        <li>{$t(clip === 'ios' ? 'installhint.inapp.ios' : 'installhint.inapp.android')}</li>
                    {/if}
                    {#each ['1', '2'] as const as k (k)}
                        <li>{$t(`installhint.${clip}.${k}`)}</li>
                    {/each}
                </ol>
                <p class="install-after">{$t('installhint.after')}</p>
                {#if !failed[clip]}
                    <!-- svelte-ignore a11y_media_has_caption -->
                    <video
                        class="install-video"
                        class:ready={videoReady}
                        src={video.src}
                        width={video.width}
                        height={video.height}
                        style:--ar={video.width / video.height}
                        muted
                        playsinline
                        loop
                        autoplay
                        controls
                        preload="metadata"
                        aria-label={$t('installhint.video')}
                        onloadeddata={() => (videoReady = true)}
                        onerror={() => (failed[clip] = true)}
                    ></video>
                {/if}
            {/if}
        </div>
    </Modal>
{/if}
