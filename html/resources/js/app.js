import { App } from '@inertiajs/inertia-svelte';
import { InertiaProgress } from '@inertiajs/progress';

InertiaProgress.init();

const app = document.getElementById('app');

new App({
    target: app,
    props: {
        initialPage: JSON.parse(app.dataset.page),
        resolveComponent: name => import(`./Pages/${name}.svelte`),
    },
});
