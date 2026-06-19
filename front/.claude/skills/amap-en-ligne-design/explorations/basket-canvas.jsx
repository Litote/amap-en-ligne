function PanierCanvasApp() {
  const M = window.PanierMarks;
  const T = window.PanierTomateMarks;
  const W = 520, H = 460;
  const make = (id, label, name, tagline, Mark) => (
    <DCArtboard id={id} label={label} width={W} height={H}>
      <LogoArtboard name={name} tagline={tagline} Mark={Mark} lockupProps={{style: 'two-tone'}}/>
    </DCArtboard>
  );
  return (
    <DesignCanvas>
      <DCSection
        id="panier-carotte-tomate"
        title="Carotte + tomate"
        subtitle="Quatre façons d'associer les deux légumes dans le panier.">
        {make('v9',  'V9 · Duo classique',  'V9 · DUO CLASSIQUE',
          'Carotte à gauche (triangle pointu), tomate à droite. Les deux légumes posés côte à côte, lisibles séparément.',
          T.MarkBasketV9)}
        {make('v10', 'V10 · Tomate devant', 'V10 · TOMATE DEVANT',
          'Tomate au premier plan, qui chevauche le bord du panier. Deux pointes de carotte visibles derrière.',
          T.MarkBasketV10)}
        {make('v11', 'V11 · Trio',          'V11 · TRIO',
          'Carotte + tomate + aubergine — un panier vraiment garni, suggère l\'abondance d\'une vraie livraison.',
          T.MarkBasketV11)}
        {make('v12', 'V12 · Côte à côte',   'V12 · CÔTE À CÔTE',
          'Carotte et tomate à la même taille, équilibrées. Lisible comme « deux ingrédients » avec un poids visuel égal.',
          T.MarkBasketV12)}
      </DCSection>
      <DCSection
        id="panier-variations"
        title="Variations précédentes"
        subtitle="Les huit options de la dernière itération, pour référence.">
        {make('v1', 'V1 · Carotte pointue',  'V1 · CAROTTE POINTUE',
          'Forme triangulaire claire, pointe nette qui descend dans le panier.',
          M.MarkBasketV1)}
        {make('v2', 'V2 · Bouquet 3 carottes', 'V2 · BOUQUET DE CAROTTES',
          'Trois petites carottes alignées.',
          M.MarkBasketV2)}
        {make('v3', 'V3 · Salade verte',    'V3 · SALADE',
          'Que des feuilles vertes — mono-couleur.',
          M.MarkBasketV3)}
        {make('v4', 'V4 · Panaché',         'V4 · PANACHÉ',
          'Carotte + longues tiges (poireau).',
          M.MarkBasketV4)}
        {make('v5', 'V5 · Panier seul',     'V5 · PANIER SEUL',
          'Minimal — petite feuille décorative.',
          M.MarkBasketV5)}
        {make('v6', 'V6 · Tomate ronde',    'V6 · TOMATE',
          'Panier arrondi + tomate.',
          M.MarkBasketV6)}
        {make('v7', 'V7 · Aplat',           'V7 · APLAT',
          'Pas de tissage — silhouette en aplat.',
          M.MarkBasketV7)}
        {make('v8', 'V8 · Pomme',           'V8 · POMME',
          'Panier arrondi + pomme rouge.',
          M.MarkBasketV8)}
      </DCSection>
    </DesignCanvas>
  );
}

window.PanierCanvasApp = PanierCanvasApp;
