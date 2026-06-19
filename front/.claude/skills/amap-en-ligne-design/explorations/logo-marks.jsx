// Eight logo proposals for Amap en Ligne.
// Each Mark* is a self-contained SVG (viewBox 0 0 96 96), so it can be
// sized at any scale. The "Lockup" component shows the mark next to a
// Roboto wordmark.

// Color tokens reused from the design system.
const L = {
  green: '#386A20',     // M3 primary (deeper than Material green 500)
  greenMid: '#4CAF50',  // Material Colors.green
  greenSoft: '#B7F397', // M3 primary container
  greenDark: '#1F4406',
  orange: '#FF9800',    // tertiary
  orangeSoft: '#FFB74D',
  blue: '#2196F3',
  earth: '#8D6E63',     // terracotta brown for grounding
  cream: '#FCFDF6',
  ink: '#1A1C18',
  fg2: '#43483E',
};

/* ---------- 1 · LE PANIER (woven basket) ---------- */
function MarkBasket({ size = 96 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 96 96" aria-label="Le Panier">
      {/* basket body */}
      <path d="M14 38 H82 L74 80 C73 84, 70 86, 66 86 H30 C26 86, 23 84, 22 80 Z" fill={L.greenSoft} stroke={L.green} strokeWidth="3" strokeLinejoin="round"/>
      {/* weave verticals */}
      <line x1="30" y1="42" x2="32" y2="82" stroke={L.green} strokeWidth="2" strokeLinecap="round"/>
      <line x1="42" y1="42" x2="43" y2="82" stroke={L.green} strokeWidth="2" strokeLinecap="round"/>
      <line x1="54" y1="42" x2="53" y2="82" stroke={L.green} strokeWidth="2" strokeLinecap="round"/>
      <line x1="66" y1="42" x2="64" y2="82" stroke={L.green} strokeWidth="2" strokeLinecap="round"/>
      {/* weave horizontals */}
      <line x1="20" y1="52" x2="76" y2="52" stroke={L.green} strokeWidth="2" strokeLinecap="round"/>
      <line x1="22" y1="64" x2="74" y2="64" stroke={L.green} strokeWidth="2" strokeLinecap="round"/>
      <line x1="24" y1="76" x2="72" y2="76" stroke={L.green} strokeWidth="2" strokeLinecap="round"/>
      {/* handle */}
      <path d="M22 38 C22 18, 74 18, 74 38" fill="none" stroke={L.green} strokeWidth="4" strokeLinecap="round"/>
      {/* veggie peek — carrot top */}
      <path d="M50 32 L48 22 L52 26 L54 18 L56 26 L60 22 L58 32 Z" fill={L.greenMid}/>
      <path d="M48 32 L62 32 L58 42 Q56 44 52 44 Z" fill={L.orange}/>
    </svg>
  );
}

/* ---------- 2 · LA POUSSE (sprout) ---------- */
function MarkSprout({ size = 96 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 96 96" aria-label="La Pousse">
      {/* soil */}
      <ellipse cx="48" cy="80" rx="30" ry="4" fill={L.earth}/>
      {/* stem */}
      <path d="M48 78 V42" stroke={L.green} strokeWidth="4" strokeLinecap="round"/>
      {/* left leaf */}
      <path d="M48 56 C30 56, 22 44, 26 32 C40 32, 48 42, 48 56 Z" fill={L.greenMid}/>
      <path d="M48 56 C36 52, 30 44, 28 36" stroke={L.greenDark} strokeWidth="1.5" fill="none"/>
      {/* right leaf */}
      <path d="M48 50 C66 50, 74 38, 70 26 C56 26, 48 36, 48 50 Z" fill={L.green}/>
      <path d="M48 50 C60 46, 66 38, 68 30" stroke={L.cream} strokeWidth="1.5" fill="none" opacity="0.5"/>
    </svg>
  );
}

/* ---------- 3 · LA CAROTTE (refined carrot) ---------- */
function MarkCarrot({ size = 96 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 96 96" aria-label="La Carotte">
      {/* leaves */}
      <path d="M48 30 L42 14 L46 20 L46 12 L50 20 L50 12 L54 20 L54 14 Z" fill={L.green}/>
      <path d="M48 30 C48 22, 56 18, 62 22 C66 18, 72 22, 70 28 Z" fill={L.greenMid}/>
      <path d="M48 30 C48 22, 40 18, 34 22 C30 18, 24 22, 26 28 Z" fill={L.greenMid}/>
      {/* body */}
      <path d="M30 32 L66 32 L52 84 C50 88, 46 88, 44 84 Z" fill={L.orange}/>
      {/* highlight stripes */}
      <line x1="36" y1="42" x2="60" y2="42" stroke={L.orangeSoft} strokeWidth="2" strokeLinecap="round"/>
      <line x1="38" y1="54" x2="58" y2="54" stroke={L.orangeSoft} strokeWidth="2" strokeLinecap="round"/>
      <line x1="40" y1="66" x2="56" y2="66" stroke={L.orangeSoft} strokeWidth="2" strokeLinecap="round"/>
      <line x1="44" y1="76" x2="52" y2="76" stroke={L.orangeSoft} strokeWidth="2" strokeLinecap="round"/>
    </svg>
  );
}

/* ---------- 4 · LES MAINS (two hands / exchange) ---------- */
function MarkHands({ size = 96 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 96 96" aria-label="Les Mains">
      {/* left hand (producer) */}
      <path d="M14 56 C14 40, 28 36, 36 44 L48 56 L34 70 C26 78, 14 72, 14 56 Z" fill={L.green}/>
      {/* right hand (consumer) */}
      <path d="M82 40 C82 56, 68 60, 60 52 L48 40 L62 26 C70 18, 82 24, 82 40 Z" fill={L.orange}/>
      {/* leaf in middle */}
      <ellipse cx="48" cy="48" rx="9" ry="13" fill={L.greenSoft}/>
      <path d="M48 35 V61" stroke={L.green} strokeWidth="1.5"/>
    </svg>
  );
}

/* ---------- 5 · LE CERCLE AMAP (badge/seal) ---------- */
function MarkBadge({ size = 96 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 96 96" aria-label="Le Cercle AMAP">
      <circle cx="48" cy="48" r="42" fill={L.green}/>
      <circle cx="48" cy="48" r="42" fill="none" stroke={L.cream} strokeWidth="2" strokeDasharray="2 4"/>
      {/* sprout in center */}
      <path d="M48 64 V40" stroke={L.cream} strokeWidth="3" strokeLinecap="round"/>
      <path d="M48 48 C40 48, 36 42, 38 36 C46 36, 48 42, 48 48 Z" fill={L.greenSoft}/>
      <path d="M48 44 C56 44, 60 38, 58 32 C50 32, 48 38, 48 44 Z" fill={L.cream}/>
      <text x="48" y="84" textAnchor="middle" fill={L.cream} fontSize="9" fontWeight="700" letterSpacing="2" fontFamily="Roboto">AMAP</text>
    </svg>
  );
}

/* ---------- 6 · LE RÉSEAU (federation nodes) ---------- */
function MarkNetwork({ size = 96 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 96 96" aria-label="Le Réseau">
      {/* connections */}
      <line x1="24" y1="28" x2="48" y2="48" stroke={L.green} strokeWidth="2"/>
      <line x1="72" y1="28" x2="48" y2="48" stroke={L.green} strokeWidth="2"/>
      <line x1="24" y1="68" x2="48" y2="48" stroke={L.green} strokeWidth="2"/>
      <line x1="72" y1="68" x2="48" y2="48" stroke={L.green} strokeWidth="2"/>
      <line x1="24" y1="28" x2="24" y2="68" stroke={L.green} strokeWidth="1.5" opacity="0.4"/>
      <line x1="72" y1="28" x2="72" y2="68" stroke={L.green} strokeWidth="1.5" opacity="0.4"/>
      {/* center node — bigger, with leaf */}
      <circle cx="48" cy="48" r="14" fill={L.green}/>
      <path d="M48 56 V42 M48 48 C44 48, 41 45, 42 41 C46 41, 48 44, 48 48 Z M48 46 C52 46, 55 43, 54 39 C50 39, 48 42, 48 46 Z" fill={L.cream} stroke={L.cream} strokeWidth="0.5"/>
      {/* outer nodes */}
      <circle cx="24" cy="28" r="7" fill={L.greenSoft} stroke={L.green} strokeWidth="2"/>
      <circle cx="72" cy="28" r="7" fill={L.greenSoft} stroke={L.green} strokeWidth="2"/>
      <circle cx="24" cy="68" r="7" fill={L.greenSoft} stroke={L.green} strokeWidth="2"/>
      <circle cx="72" cy="68" r="7" fill={L.orange} stroke={L.green} strokeWidth="2"/>
    </svg>
  );
}

/* ---------- 7 · LE SOLEIL (sun + leaf) ---------- */
function MarkSun({ size = 96 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 96 96" aria-label="Le Soleil">
      {/* sun rays */}
      <g stroke={L.orange} strokeWidth="3" strokeLinecap="round">
        <line x1="48" y1="6" x2="48" y2="16"/>
        <line x1="48" y1="80" x2="48" y2="90"/>
        <line x1="6" y1="48" x2="16" y2="48"/>
        <line x1="80" y1="48" x2="90" y2="48"/>
        <line x1="18" y1="18" x2="25" y2="25"/>
        <line x1="71" y1="71" x2="78" y2="78"/>
        <line x1="78" y1="18" x2="71" y2="25"/>
        <line x1="18" y1="78" x2="25" y2="71"/>
      </g>
      {/* sun disc */}
      <circle cx="48" cy="48" r="22" fill={L.orange}/>
      {/* leaf overlay */}
      <path d="M48 64 C32 60, 28 44, 36 32 C50 36, 56 50, 48 64 Z" fill={L.green}/>
      <path d="M40 56 C42 50, 44 44, 48 38" stroke={L.cream} strokeWidth="1.5" fill="none" opacity="0.5"/>
    </svg>
  );
}

/* ---------- 8 · L'ÉPI (wheat / grain) ---------- */
function MarkWheat({ size = 96 }) {
  const grain = (cx, cy, rot) => (
    <ellipse cx={cx} cy={cy} rx="3.5" ry="6" fill={L.orange} transform={`rotate(${rot} ${cx} ${cy})`}/>
  );
  return (
    <svg width={size} height={size} viewBox="0 0 96 96" aria-label="L'Épi">
      {/* stem */}
      <path d="M48 86 C48 70, 48 54, 48 30" stroke={L.green} strokeWidth="3" strokeLinecap="round" fill="none"/>
      {/* grains — left column */}
      {grain(42, 32, -18)}
      {grain(40, 42, -18)}
      {grain(38, 52, -18)}
      {grain(36, 62, -18)}
      {/* grains — right column */}
      {grain(54, 32, 18)}
      {grain(56, 42, 18)}
      {grain(58, 52, 18)}
      {grain(60, 62, 18)}
      {/* top grain */}
      {grain(48, 24, 0)}
      {/* tassels */}
      <path d="M42 32 L34 24 M40 42 L30 36 M38 52 L28 48 M36 62 L26 62" stroke={L.greenMid} strokeWidth="1.5" strokeLinecap="round" fill="none"/>
      <path d="M54 32 L62 24 M56 42 L66 36 M58 52 L68 48 M60 62 L70 62" stroke={L.greenMid} strokeWidth="1.5" strokeLinecap="round" fill="none"/>
    </svg>
  );
}

/* ---------- Lockup wrapper ---------- */
function Lockup({ Mark, accent = L.green, secondary = L.fg2, weight = 700, style = 'amap-bold' }) {
  // wordmark variations
  const word = (() => {
    if (style === 'two-tone') {
      return (
        <span style={{font:'700 26px Roboto', color: accent, letterSpacing: -0.5, whiteSpace:'nowrap'}}>
          <span style={{color: L.ink}}>Amap </span>
          <span style={{color: secondary, fontWeight: 400}}>en </span>
          <span>Ligne</span>
        </span>
      );
    }
    if (style === 'lowercase') {
      return <span style={{font: '500 24px Roboto', color: L.ink, letterSpacing: -0.5, whiteSpace:'nowrap'}}>amap·en·ligne</span>;
    }
    if (style === 'serif') {
      return <span style={{font: '700 26px "Bricolage Grotesque", Roboto', color: L.ink, letterSpacing: -1, whiteSpace:'nowrap'}}>Amap en Ligne</span>;
    }
    // default: amap-bold
    return (
      <span style={{font:`${weight} 26px Roboto`, color: L.ink, letterSpacing: -0.5, whiteSpace:'nowrap'}}>
        Amap <span style={{color: accent}}>en Ligne</span>
      </span>
    );
  })();

  return (
    <div style={{display:'flex', alignItems:'center', gap:14}}>
      <Mark size={56}/>
      {word}
    </div>
  );
}

window.LogoMarks = { MarkBasket, MarkSprout, MarkCarrot, MarkHands, MarkBadge, MarkNetwork, MarkSun, MarkWheat };
window.LogoLockup = Lockup;
window.LogoColors = L;
