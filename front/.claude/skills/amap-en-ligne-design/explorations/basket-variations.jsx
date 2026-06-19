// Six variations on the "Le Panier" (basket) mark.
// All keep the basket concept; differ in what (if anything) peeks out and in
// basket silhouette/weave detail.

const PL = {
  green: '#386A20',
  greenMid: '#4CAF50',
  greenSoft: '#B7F397',
  greenDark: '#1F4406',
  greenLeaf: '#66BB6A',
  orange: '#E8721C',     // slightly deeper than #FF9800 — reads more like carrot
  orangeSoft: '#FFB74D',
  tomato: '#D84A3A',
  cream: '#FCFDF6',
  ink: '#1A1C18',
  fg2: '#43483E',
};

/* Shared basket silhouette (handle + body + weave) ------------------------ */
function BasketBody({ stroke = PL.green, fill = PL.greenSoft }) {
  return (
    <g>
      {/* body */}
      <path d="M14 38 H82 L74 80 C73 84, 70 86, 66 86 H30 C26 86, 23 84, 22 80 Z" fill={fill} stroke={stroke} strokeWidth="3" strokeLinejoin="round"/>
      {/* verticals */}
      <line x1="30" y1="42" x2="32" y2="82" stroke={stroke} strokeWidth="2" strokeLinecap="round"/>
      <line x1="42" y1="42" x2="43" y2="82" stroke={stroke} strokeWidth="2" strokeLinecap="round"/>
      <line x1="54" y1="42" x2="53" y2="82" stroke={stroke} strokeWidth="2" strokeLinecap="round"/>
      <line x1="66" y1="42" x2="64" y2="82" stroke={stroke} strokeWidth="2" strokeLinecap="round"/>
      {/* horizontals */}
      <line x1="20" y1="52" x2="76" y2="52" stroke={stroke} strokeWidth="2" strokeLinecap="round"/>
      <line x1="22" y1="64" x2="74" y2="64" stroke={stroke} strokeWidth="2" strokeLinecap="round"/>
      <line x1="24" y1="76" x2="72" y2="76" stroke={stroke} strokeWidth="2" strokeLinecap="round"/>
      {/* handle */}
      <path d="M22 38 C22 18, 74 18, 74 38" fill="none" stroke={stroke} strokeWidth="4" strokeLinecap="round"/>
    </g>
  );
}

/* Rounder/wider basket silhouette (V6) ----------------------------------- */
function BasketBodyRound({ stroke = PL.green, fill = PL.greenSoft }) {
  return (
    <g>
      <path d="M10 40 Q10 38, 12 38 H84 Q86 38, 86 40 L78 82 C77 86, 73 88, 68 88 H28 C23 88, 19 86, 18 82 Z" fill={fill} stroke={stroke} strokeWidth="3" strokeLinejoin="round"/>
      {/* horizontal weave only — cleaner */}
      <path d="M14 52 H82" stroke={stroke} strokeWidth="2" strokeLinecap="round"/>
      <path d="M17 64 H79" stroke={stroke} strokeWidth="2" strokeLinecap="round"/>
      <path d="M20 76 H76" stroke={stroke} strokeWidth="2" strokeLinecap="round"/>
      <path d="M16 40 C16 16, 80 16, 80 40" fill="none" stroke={stroke} strokeWidth="4" strokeLinecap="round"/>
    </g>
  );
}

/* V1 · Carrot — pointed, properly triangular ----------------------------- */
function MarkBasketV1({ size = 96 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 96 96" aria-label="Panier · carotte pointue">
      <BasketBody/>
      {/* carrot leaves — fuller bunch */}
      <path d="M48 30 L40 14 L44 22 L42 12 L48 22 L50 10 L52 22 L54 12 L52 22 L56 14 Z" fill={PL.green}/>
      <path d="M52 30 C56 24, 64 22, 66 28 Z" fill={PL.greenLeaf}/>
      <path d="M44 30 C40 24, 32 22, 30 28 Z" fill={PL.greenLeaf}/>
      {/* carrot body — clearly triangular, pointed tip below rim */}
      <path d="M40 32 L56 32 L48 50 Z" fill={PL.orange} stroke={PL.greenDark} strokeWidth="0.5"/>
      {/* highlight stripes */}
      <line x1="43" y1="38" x2="53" y2="38" stroke={PL.orangeSoft} strokeWidth="1.5" strokeLinecap="round"/>
      <line x1="45" y1="43" x2="51" y2="43" stroke={PL.orangeSoft} strokeWidth="1.5" strokeLinecap="round"/>
    </svg>
  );
}

/* V2 · Bouquet of 3 carrots ---------------------------------------------- */
function MarkBasketV2({ size = 96 }) {
  // a small bundle: left carrot tilted left, center upright, right tilted right
  return (
    <svg width={size} height={size} viewBox="0 0 96 96" aria-label="Panier · bouquet de carottes">
      <BasketBody/>
      {/* combined leaves */}
      <g fill={PL.green}>
        <path d="M30 30 L26 18 L30 22 L30 14 L34 22 L36 14 L36 22 L40 16 L38 30 Z"/>
        <path d="M44 28 L40 12 L44 18 L46 10 L48 18 L52 8 L52 18 L56 12 L54 28 Z"/>
        <path d="M58 30 L56 16 L60 22 L62 14 L64 22 L68 16 L70 22 L66 30 Z"/>
      </g>
      {/* three carrots, all pointed triangles */}
      <path d="M26 32 L36 32 L31 48 Z" fill={PL.orange}/>
      <path d="M42 30 L54 30 L48 52 Z" fill={PL.orange}/>
      <path d="M58 32 L68 32 L63 48 Z" fill={PL.orange}/>
    </svg>
  );
}

/* V3 · Lettuce / leaves only (no orange) --------------------------------- */
function MarkBasketV3({ size = 96 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 96 96" aria-label="Panier · salade">
      <BasketBody fill={PL.cream}/>
      {/* ruffled lettuce leaves bursting out the top */}
      <g fill={PL.greenLeaf}>
        <path d="M30 34 C26 26, 30 16, 38 16 C40 22, 36 30, 32 34 Z"/>
        <path d="M40 32 C36 22, 42 12, 50 14 C52 22, 48 30, 42 32 Z"/>
        <path d="M50 32 C48 20, 56 12, 64 16 C66 24, 60 32, 54 32 Z"/>
        <path d="M62 34 C62 24, 70 18, 76 24 C74 32, 68 36, 62 34 Z"/>
      </g>
      <g fill={PL.green}>
        <path d="M34 32 C30 26, 32 18, 38 18 C40 24, 38 30, 34 32 Z" opacity="0.5"/>
        <path d="M44 30 C42 22, 46 16, 52 18 C52 24, 48 30, 44 30 Z" opacity="0.5"/>
        <path d="M54 30 C52 22, 58 16, 64 20 C64 26, 60 32, 56 32 Z" opacity="0.5"/>
      </g>
    </svg>
  );
}

/* V4 · Mixed bunch — carrot + tall green stems (poireau-style) ---------- */
function MarkBasketV4({ size = 96 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 96 96" aria-label="Panier · panaché">
      <BasketBody/>
      {/* tall stems on the right */}
      <path d="M58 32 V12" stroke={PL.greenLeaf} strokeWidth="3" strokeLinecap="round"/>
      <path d="M62 32 V14" stroke={PL.greenLeaf} strokeWidth="3" strokeLinecap="round"/>
      <path d="M66 32 V18" stroke={PL.greenLeaf} strokeWidth="3" strokeLinecap="round"/>
      <path d="M58 12 C58 10, 60 8, 62 10 C62 8, 66 8, 66 12 C66 14, 62 16, 58 14 Z" fill={PL.green}/>
      {/* carrot on the left — pointy */}
      <g fill={PL.green}>
        <path d="M36 30 L32 18 L34 22 L34 16 L38 22 L40 16 L42 22 L44 18 L40 30 Z"/>
      </g>
      <path d="M32 32 L44 32 L38 52 Z" fill={PL.orange}/>
      <line x1="35" y1="38" x2="41" y2="38" stroke={PL.orangeSoft} strokeWidth="1.2"/>
    </svg>
  );
}

/* V5 · Clean basket — no contents ---------------------------------------- */
function MarkBasketV5({ size = 96 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 96 96" aria-label="Panier · vide">
      <BasketBody fill={PL.cream}/>
      {/* one tiny leaf accent on rim */}
      <path d="M48 36 C44 34, 42 28, 46 24 C50 26, 52 32, 48 36 Z" fill={PL.greenLeaf}/>
      <path d="M48 26 V36" stroke={PL.green} strokeWidth="1" opacity="0.6"/>
    </svg>
  );
}

/* V6 · Rounder basket, tomato peeking ------------------------------------ */
function MarkBasketV6({ size = 96 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 96 96" aria-label="Panier · tomate">
      <BasketBodyRound/>
      {/* tomato — round red ball */}
      <circle cx="48" cy="36" r="9" fill={PL.tomato}/>
      <path d="M48 36 m-9 0 a9 6 0 0 1 18 0" fill="none" stroke="#A6372C" strokeWidth="1" opacity="0.4"/>
      {/* stem + leaves */}
      <path d="M48 28 V22" stroke={PL.green} strokeWidth="2" strokeLinecap="round"/>
      <path d="M48 28 C42 24, 38 26, 40 30 Z" fill={PL.green}/>
      <path d="M48 28 C54 24, 58 26, 56 30 Z" fill={PL.green}/>
      {/* small highlight on tomato */}
      <ellipse cx="44" cy="33" rx="2" ry="1.5" fill="#fff" opacity="0.4"/>
    </svg>
  );
}

/* V7 · Two-color simplified — flat solid, no weave details ------------- */
function MarkBasketV7({ size = 96 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 96 96" aria-label="Panier · simplifié">
      {/* solid basket — only outline, no weave noise */}
      <path d="M14 38 H82 L74 80 C73 84, 70 86, 66 86 H30 C26 86, 23 84, 22 80 Z" fill={PL.greenSoft}/>
      <path d="M14 38 H82 L74 80 C73 84, 70 86, 66 86 H30 C26 86, 23 84, 22 80 Z" fill="none" stroke={PL.green} strokeWidth="4" strokeLinejoin="round"/>
      <path d="M22 38 C22 18, 74 18, 74 38" fill="none" stroke={PL.green} strokeWidth="4" strokeLinecap="round"/>
      {/* one big bold carrot — much more visible */}
      <path d="M38 30 L58 30 L48 56 Z" fill={PL.orange} stroke={PL.greenDark} strokeWidth="0.5"/>
      {/* leaves */}
      <path d="M40 30 L36 16 L40 22 L40 14 L44 22 L46 14 L48 22 L48 14 L52 22 L52 14 L56 22 L58 16 L54 30 Z" fill={PL.green}/>
    </svg>
  );
}

/* V8 · Heart-shape basket — gentler curve, fruit + leaf ----------------- */
function MarkBasketV8({ size = 96 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 96 96" aria-label="Panier · pomme">
      <BasketBodyRound/>
      {/* apple */}
      <path d="M48 36 C40 36, 36 42, 38 50 C40 56, 48 56, 48 56 C48 56, 56 56, 58 50 C60 42, 56 36, 48 36 Z" fill="#C73A2A"/>
      <path d="M48 36 V32 C48 28, 52 26, 56 26" stroke={PL.green} strokeWidth="2" strokeLinecap="round" fill="none"/>
      <path d="M50 32 C56 28, 62 30, 62 30 C60 26, 54 26, 50 32 Z" fill={PL.green}/>
    </svg>
  );
}

window.PanierMarks = {
  MarkBasketV1, MarkBasketV2, MarkBasketV3, MarkBasketV4,
  MarkBasketV5, MarkBasketV6, MarkBasketV7, MarkBasketV8,
};

/* ============================================================
   CARROT + TOMATO variations
   ============================================================ */

/* V9 · Classic duo — carrot left, tomato right ------------------------- */
function MarkBasketV9({ size = 96 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 96 96" aria-label="Panier · carotte + tomate">
      <BasketBody/>
      {/* carrot leaves */}
      <path d="M34 30 L30 14 L33 20 L33 12 L36 20 L38 12 L39 20 L42 14 L38 30 Z" fill={PL.green}/>
      {/* carrot — triangle, pointed */}
      <path d="M30 32 L42 32 L36 52 Z" fill={PL.orange}/>
      <line x1="33" y1="38" x2="39" y2="38" stroke={PL.orangeSoft} strokeWidth="1.3" strokeLinecap="round"/>
      <line x1="34" y1="43" x2="38" y2="43" stroke={PL.orangeSoft} strokeWidth="1.3" strokeLinecap="round"/>

      {/* tomato — round red ball, slightly higher than rim */}
      <circle cx="60" cy="34" r="10" fill={PL.tomato}/>
      {/* tomato stem + leaves */}
      <path d="M60 26 V22" stroke={PL.green} strokeWidth="2" strokeLinecap="round"/>
      <path d="M60 26 C54 22, 50 24, 52 28 Z" fill={PL.green}/>
      <path d="M60 26 C66 22, 70 24, 68 28 Z" fill={PL.green}/>
      {/* tomato highlight */}
      <ellipse cx="56" cy="31" rx="2.2" ry="1.6" fill="#fff" opacity="0.35"/>
    </svg>
  );
}

/* V10 · Tomato peeking front, carrots behind -------------------------- */
function MarkBasketV10({ size = 96 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 96 96" aria-label="Panier · tomate devant">
      <BasketBody/>
      {/* two carrot tops behind */}
      <g fill={PL.green}>
        <path d="M36 30 L32 16 L36 22 L36 14 L40 22 L42 14 L42 22 L46 18 L42 30 Z"/>
        <path d="M56 30 L52 16 L56 22 L56 14 L60 22 L62 14 L62 22 L66 18 L62 30 Z"/>
      </g>
      {/* carrots tips visible */}
      <path d="M34 32 L44 32 L39 44 Z" fill={PL.orange}/>
      <path d="M54 32 L64 32 L59 44 Z" fill={PL.orange}/>
      {/* tomato — overlapping rim, in front */}
      <circle cx="48" cy="40" r="11" fill={PL.tomato}/>
      <path d="M48 31 V26" stroke={PL.green} strokeWidth="2" strokeLinecap="round"/>
      <path d="M48 31 C42 27, 38 29, 40 33 Z" fill={PL.green}/>
      <path d="M48 31 C54 27, 58 29, 56 33 Z" fill={PL.green}/>
      <ellipse cx="44" cy="37" rx="2.4" ry="1.8" fill="#fff" opacity="0.35"/>
    </svg>
  );
}

/* V11 · Abundant trio — carrot + tomato + eggplant ------------------- */
function MarkBasketV11({ size = 96 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 96 96" aria-label="Panier · trio">
      <BasketBody/>
      {/* eggplant — back-left, oval purple body */}
      <path d="M22 38 C18 30, 22 22, 28 20 C34 22, 36 30, 32 38 Z" fill="#5E2D6B"/>
      {/* eggplant highlight */}
      <path d="M24 32 C24 28, 26 24, 30 24" stroke="#8E4FA0" strokeWidth="1.5" strokeLinecap="round" fill="none"/>
      {/* eggplant calyx (green top) */}
      <path d="M24 22 C22 18, 24 16, 28 18 L30 14 L32 18 C34 16, 36 18, 34 22 Z" fill={PL.green}/>
      <path d="M28 18 V12" stroke={PL.green} strokeWidth="1.5" strokeLinecap="round"/>

      {/* carrot, slightly tilted left */}
      <g fill={PL.green}>
        <path d="M40 30 L36 14 L39 20 L39 12 L42 20 L44 12 L45 20 L48 14 L44 30 Z"/>
      </g>
      <path d="M37 32 L47 32 L42 50 Z" fill={PL.orange}/>
      <line x1="39" y1="38" x2="45" y2="38" stroke={PL.orangeSoft} strokeWidth="1.3" strokeLinecap="round"/>

      {/* tomato on the right */}
      <circle cx="64" cy="36" r="9" fill={PL.tomato}/>
      <path d="M64 28 V24" stroke={PL.green} strokeWidth="2" strokeLinecap="round"/>
      <path d="M64 28 C59 25, 56 27, 58 30 Z" fill={PL.green}/>
      <path d="M64 28 C69 25, 72 27, 70 30 Z" fill={PL.green}/>
      <ellipse cx="61" cy="34" rx="2" ry="1.4" fill="#fff" opacity="0.35"/>
    </svg>
  );
}

/* V12 · Balanced side-by-side, both same size ------------------------ */
function MarkBasketV12({ size = 96 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 96 96" aria-label="Panier · côte à côte">
      <BasketBody/>
      {/* carrot — left, bigger, fully visible */}
      <g fill={PL.green}>
        <path d="M36 28 L32 12 L35 18 L35 10 L38 18 L40 8 L41 18 L44 10 L44 18 L48 14 L42 28 Z"/>
      </g>
      <path d="M32 30 L46 30 L39 54 Z" fill={PL.orange}/>
      <line x1="35" y1="37" x2="43" y2="37" stroke={PL.orangeSoft} strokeWidth="1.4" strokeLinecap="round"/>
      <line x1="36" y1="43" x2="42" y2="43" stroke={PL.orangeSoft} strokeWidth="1.4" strokeLinecap="round"/>
      {/* tomato — right, same diameter as carrot top */}
      <circle cx="60" cy="38" r="11" fill={PL.tomato}/>
      <path d="M60 30 V25" stroke={PL.green} strokeWidth="2.4" strokeLinecap="round"/>
      <path d="M60 30 C53 25, 49 28, 51 33 Z" fill={PL.green}/>
      <path d="M60 30 C67 25, 71 28, 69 33 Z" fill={PL.green}/>
      <ellipse cx="56" cy="35" rx="2.6" ry="1.8" fill="#fff" opacity="0.4"/>
    </svg>
  );
}

window.PanierTomateMarks = { MarkBasketV9, MarkBasketV10, MarkBasketV11, MarkBasketV12 };
