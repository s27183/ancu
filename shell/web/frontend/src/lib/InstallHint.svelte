<script lang="ts">
    // Bilingual -> the bilingual plan reaches the phone it is read on -> the web frontend ->
    // the Add to Home Screen pill and its sheet (behavior 153; the rule and its block:
    // installHint.ts). The pill sits at the right of the home's top row, opposite the
    // Introduction pill; its sheet gives this device's steps and, once Son publishes it,
    // the clip installVideo names for this device (muted, inline, looping, with controls;
    // iPhone or Android, none on a computer: behavior 158). A missing file fires the
    // video's error, and the player is dropped, so the sheet never shows a broken player.
    // The iPhone clip is cropped to 540×1000, above the phone's dock, so no frame shows the
    // apps pinned on Son's own phone (behavior 156); the player takes each clip's own aspect
    // (--ar), its height capped at 60vh, so a tall clip has no bars beside it.
    // Where the browser offers an install (Chrome, Edge: caught in app.html as
    // window.__ancuInstall), the sheet puts a one-tap Install button above the steps; the
    // tap opens the browser's own dialog. Install says so in the sheet and drops the pill;
    // Cancel drops the button for the rest of the page load: Chrome for Android makes a new
    // offer at once after a dismissal (seen on the Pixel 9 Pro emulator), and the visitor has
    // just said no; the menu steps stay (behavior 157).
    import { onMount } from 'svelte';
    import { t } from '$lib/i18n';
    import Modal from '$lib/Modal.svelte';
    import { browserHintEnv, installSteps, installVideo, showInstallButton, type InstallSteps, type OfferState } from '$lib/installHint';

    let steps = $state<InstallSteps | null>(null);
    const video = $derived(installVideo(steps));
    let open = $state(false);
    let videoOk = $state(true);
    let videoReady = $state(false);
    let offerState = $state<OfferState>('none');
    let installed = $state(false);
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
        videoOk = true;
        videoReady = false;
        open = true;
    }
</script>

{#if steps && !installed}
    <button type="button" class="home-pill install-pill" onclick={show} aria-haspopup="dialog">
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
                {#if showInstallButton(steps, offerState)}
                    <button type="button" class="btn btn-primary install-now" onclick={install}>{$t('installhint.install')}</button>
                {/if}
                <ol class="install-steps">
                    {#if steps.inApp}
                        <li>{$t(steps.platform === 'ios' ? 'installhint.inapp.ios' : 'installhint.inapp.android')}</li>
                    {/if}
                    {#each ['1', '2'] as const as k (k)}
                        <li>{$t(`installhint.${steps.platform}.${k}`)}</li>
                    {/each}
                </ol>
                <p class="install-after">{$t('installhint.after')}</p>
                {#if video && videoOk}
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
                        onerror={() => (videoOk = false)}
                    ></video>
                {/if}
            {/if}
        </div>
    </Modal>
{/if}
