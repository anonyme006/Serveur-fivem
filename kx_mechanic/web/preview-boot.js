/* Preview bootstrap — mocks FiveM NUI callbacks for browser demo */
(function () {
    const originalFetch = window.fetch.bind(window);

    const mockMenu = {
        job: { name: 'mechanic', grade: 4, onduty: true, label: 'Los Santos Customs' },
        playerName: 'Alex Rivera',
        permissions: {
            diagnose: true, repair: true, clean: true, tires: true, maintenance: true,
            body: true, performance: true, billing: true, stock: true, orders: true,
            employees: true, dashboard: true, management: true, lift: true,
        },
        config: {
            enableBilling: true,
            enablePerformance: true,
            enableMaintenance: true,
            enableOrders: true,
            enableDashboard: true,
        },
        categories: [
            {
                id: 'repair', label: 'Réparation', icon: 'wrench',
                services: [
                    { id: 'repair_engine', label: 'Réparation moteur', description: 'Remise en état du bloc moteur et des composants associés.', price: 750, duration: 15000, materials: [{ count: 1, label: 'Pièce moteur' }, { count: 2, label: 'Kit de réparation' }] },
                    { id: 'repair_brakes', label: 'Réparation freins', description: 'Remplacement des plaquettes et révision du circuit.', price: 350, duration: 10000, materials: [{ count: 1, label: 'Pièce freins' }, { count: 1, label: 'Kit de réparation' }] },
                    { id: 'repair_transmission', label: 'Réparation transmission', description: 'Révision de la boîte de vitesses.', price: 600, duration: 14000, materials: [{ count: 1, label: 'Pièce transmission' }] },
                    { id: 'repair_suspension', label: 'Réparation suspension', description: 'Remise en état des amortisseurs.', price: 450, duration: 11000, materials: [{ count: 1, label: 'Pièce suspension' }] },
                ],
            },
            {
                id: 'performance', label: 'Performance', icon: 'gauge-high',
                services: [
                    { id: 'engine_3', label: 'Moteur niveau 3', description: 'Amélioration moteur niveau 3.', price: 7000, duration: 30000, materials: [{ count: 4, label: 'Pièce moteur' }] },
                    { id: 'turbo', label: 'Turbo', description: 'Installation d\'un turbo.', price: 5000, duration: 20000, materials: [{ count: 2, label: 'Pièce moteur' }] },
                    { id: 'brakes_race', label: 'Freins race', description: 'Freins course.', price: 4000, duration: 18000, materials: [{ count: 3, label: 'Pièce freins' }] },
                ],
            },
            {
                id: 'body', label: 'Carrosserie', icon: 'car',
                services: [
                    { id: 'repair_body', label: 'Réparation carrosserie', description: 'Répare les déformations.', price: 500, duration: 12000, materials: [{ count: 1, label: 'Kit carrosserie' }] },
                    { id: 'paint_primary', label: 'Peinture principale', description: 'Change la couleur principale.', price: 350, duration: 8000, materials: [] },
                ],
            },
            {
                id: 'tires', label: 'Pneus', icon: 'circle',
                services: [
                    { id: 'replace_tire', label: 'Changer pneu', description: 'Remplace complètement un pneu.', price: 150, duration: 8000, materials: [{ count: 1, label: 'Pneu' }] },
                    { id: 'tire_sport', label: 'Pneus sport', description: 'Monte un train sport.', price: 400, duration: 9000, materials: [{ count: 4, label: 'Pneu' }] },
                ],
            },
            {
                id: 'maintenance', label: 'Entretien', icon: 'oil-can',
                services: [
                    { id: 'oil_change', label: 'Vidange', description: 'Remplacement de l\'huile moteur.', price: 150, duration: 10000, materials: [{ count: 1, label: 'Huile moteur' }] },
                    { id: 'battery_change', label: 'Changer batterie', description: 'Installation d\'une batterie neuve.', price: 250, duration: 8000, materials: [{ count: 1, label: 'Batterie' }] },
                ],
            },
            { id: 'stock', label: 'Stock', icon: 'boxes-stacked', services: [] },
            { id: 'billing', label: 'Facturation', icon: 'file-invoice-dollar', services: [] },
            { id: 'orders', label: 'Commandes', icon: 'clipboard-list', services: [] },
            { id: 'employees', label: 'Employés', icon: 'users', services: [] },
            { id: 'management', label: 'Gestion entreprise', icon: 'building', services: [] },
        ],
    };

    const mockReport = {
        plate: 'KX 4821',
        mileage: 12480.5,
        last_service: '2026-08-12 14:22:00',
        tire_type: 'sport',
        components: [
            { id: 'engine', label: 'MOTEUR', percent: 82, bar: '████████░░' },
            { id: 'body', label: 'CARROSSERIE', percent: 73, bar: '███████░░░' },
            { id: 'transmission', label: 'TRANSMISSION', percent: 64, bar: '██████░░░░' },
            { id: 'brakes', label: 'FREINS', percent: 91, bar: '█████████░' },
            { id: 'suspension', label: 'SUSPENSION', percent: 58, bar: '█████░░░░░' },
            { id: 'clutch', label: 'EMBRAYAGE', percent: 77, bar: '███████░░░' },
            { id: 'oil', label: 'HUILE', percent: 34, bar: '███░░░░░░░' },
            { id: 'battery', label: 'BATTERIE', percent: 88, bar: '████████░░' },
            { id: 'radiator', label: 'RADIATEUR', percent: 70, bar: '███████░░░' },
            { id: 'spark_plugs', label: 'BOUGIES', percent: 45, bar: '████░░░░░░' },
            { id: 'fuel', label: 'CARBURANT', percent: 62, bar: '██████░░░░' },
            { id: 'temp', label: 'TEMPÉRATURE', percent: 72, bar: '███████░░░', raw: 94 },
        ],
        tires: [
            { id: 'fl', label: 'Avant gauche', percent: 100 },
            { id: 'fr', label: 'Avant droit', percent: 86 },
            { id: 'rl', label: 'Arrière gauche', percent: 92 },
            { id: 'rr', label: 'Arrière droit', percent: 78 },
        ],
    };

    window.fetch = async function (url, options) {
        if (typeof url === 'string' && url.includes('https://kx_mechanic/')) {
            const name = url.split('https://kx_mechanic/')[1];
            const body = options && options.body ? JSON.parse(options.body) : {};

            if (name === 'close') return Response.json({ ok: true });
            if (name === 'notify') return Response.json({ ok: true });
            if (name === 'runService') {
                document.getElementById('toast').textContent = 'Preview: intervention simulée';
                document.getElementById('toast').classList.remove('hidden');
                return Response.json({ ok: true });
            }
            if (name === 'diagnose') {
                window.postMessage({
                    action: 'open',
                    data: {
                        view: 'diagnostic',
                        report: mockReport,
                        menu: mockMenu,
                        shopName: 'Los Santos Customs',
                        vehicle: { plate: 'KX 4821', model: 'SULTAN RS' },
                    },
                }, '*');
                return Response.json({ ok: true });
            }
            if (name === 'getNearbyPlayers') {
                return Response.json({ ok: true, players: [{ id: 12, name: 'Jordan Blake' }, { id: 27, name: 'Sam Ortega' }] });
            }
            if (name === 'createInvoice') return Response.json({ ok: true, message: 'Facture envoyée (preview).' });
            if (name === 'getOrders') {
                return Response.json({
                    ok: true,
                    catalog: [
                        { item: 'engine_part', label: 'Pièce moteur', unitPrice: 250 },
                        { item: 'oil', label: 'Huile moteur', unitPrice: 40 },
                        { item: 'tire', label: 'Pneu', unitPrice: 90 },
                    ],
                    orders: [
                        { order_number: 'ORD-20260820-118234', product_label: 'Pièce moteur', quantity: 10, total_price: 2500, status: 'shipping', created_at: '2026-08-20 16:10' },
                        { order_number: 'ORD-20260820-991002', product_label: 'Huile moteur', quantity: 20, total_price: 800, status: 'delivered', created_at: '2026-08-20 12:02' },
                    ],
                });
            }
            if (name === 'createOrder') return Response.json({ ok: true, message: 'Commande passée (preview).' });
            if (name === 'getEmployees') {
                return Response.json({
                    ok: true,
                    grades: {
                        0: { label: 'Stagiaire', salary: 50 },
                        1: { label: 'Mécanicien', salary: 100 },
                        2: { label: 'Mécanicien confirmé', salary: 150 },
                        3: { label: 'Chef d\'équipe', salary: 200 },
                        4: { label: 'Patron', salary: 250 },
                    },
                    employees: [
                        { citizenid: 'ABC123', name: 'Alex Rivera', grade: 4, salary: 250 },
                        { citizenid: 'DEF456', name: 'Mia Chen', grade: 2, salary: 150 },
                        { citizenid: 'GHI789', name: 'Leo Hart', grade: 1, salary: 100 },
                    ],
                });
            }
            if (name === 'getDashboard') {
                return Response.json({
                    ok: true,
                    data: {
                        day: { revenue: 12450, repairs: 18, vehicles: 14, parts: 42 },
                        week: { revenue: 68200, repairs: 96, vehicles: 71 },
                        month: { revenue: 241800, repairs: 380, vehicles: 290 },
                        bestMechanic: { mechanic_name: 'Mia Chen', total: 18400 },
                        chart: [
                            { day: '2026-08-14', revenue: 8200 },
                            { day: '2026-08-15', revenue: 9400 },
                            { day: '2026-08-16', revenue: 6100 },
                            { day: '2026-08-17', revenue: 11200 },
                            { day: '2026-08-18', revenue: 9800 },
                            { day: '2026-08-19', revenue: 10500 },
                            { day: '2026-08-20', revenue: 12450 },
                        ],
                        lowStock: [
                            { item: 'oil', label: 'Huile moteur', count: 2 },
                            { item: 'spark_plug', label: 'Bougie', count: 4 },
                        ],
                        partsUsed: [
                            { item: 'repair_kit', total: 38 },
                            { item: 'engine_part', total: 17 },
                            { item: 'tire', total: 12 },
                        ],
                    },
                });
            }
            if (name === 'getHistory') {
                return Response.json({
                    ok: true,
                    history: [
                        { id: 1042, plate: 'KX4821', repair_label: 'Réparation moteur', mechanic_name: 'Mia Chen', price: 750, created_at: '2026-08-20 15:41' },
                        { id: 1041, plate: 'LS9910', repair_label: 'Vidange', mechanic_name: 'Leo Hart', price: 150, created_at: '2026-08-20 15:12' },
                        { id: 1040, plate: 'TR2201', repair_label: 'Pneus sport', mechanic_name: 'Alex Rivera', price: 400, created_at: '2026-08-20 14:55' },
                    ],
                });
            }
            if (name === 'getStockLog') {
                return Response.json({
                    ok: true,
                    log: [
                        { action: 'consume', item: 'engine_part', amount: 1, player_name: 'Mia Chen', reason: 'repair_engine', created_at: '2026-08-20 15:41' },
                        { action: 'order_delivery', item: 'oil', amount: 20, player_name: 'Alex Rivera', reason: 'ORD-991002', created_at: '2026-08-20 13:01' },
                    ],
                });
            }
            if (name === 'openStash') return Response.json({ ok: true });
            if (name === 'hireEmployee' || name === 'fireEmployee' || name === 'setEmployeeGrade') {
                return Response.json({ ok: true, message: 'OK (preview)' });
            }

            return Response.json({ ok: true, preview: true, received: body });
        }
        return originalFetch(url, options);
    };

    // Auto-show mock report when opening Diagnostic tab in preview
    document.addEventListener('click', (e) => {
        const tab = e.target.closest('.tablet-tab[data-tab="diagnostic"]');
        if (!tab) return;
        setTimeout(() => {
            window.postMessage({
                action: 'open',
                data: {
                    view: 'diagnostic',
                    report: mockReport,
                    menu: mockMenu,
                    shopName: 'Los Santos Customs',
                    vehicle: { plate: 'KX 4821', model: 'SULTAN RS' },
                },
            }, '*');
        }, 40);
    });

    window.addEventListener('load', () => {
        setTimeout(() => {
            window.postMessage({
                action: 'open',
                data: {
                    view: 'menu',
                    menu: mockMenu,
                    defaultCategory: 'repair',
                    shopName: 'Los Santos Customs',
                    vehicle: { plate: 'KX 4821', model: 'SULTAN RS' },
                },
            }, '*');
        }, 120);
    });
})();
