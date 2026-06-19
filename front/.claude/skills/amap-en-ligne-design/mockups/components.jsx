// Shared atoms for the documentation mockups.
// Loaded BEFORE the screen files. Exposes globals via window.

const MC = {
  green:        '#4CAF50',
  greenDark:    '#386A20',
  greenSoft:    '#B7F397',
  greenSurface: '#E8F5E9',
  blue:         '#2196F3',
  blueSoft:     '#E3F2FD',
  orange:       '#FF9800',
  orangeSoft:   '#FFF3E0',
  red:          '#B3261E',
  redSoft:      '#F9DEDC',
  ink:          '#1A1C18',
  fg1:          '#1A1C18',
  fg2:          '#43483E',
  fg3:          '#73796E',
  surface:      '#FCFDF6',
  surfaceLow:   '#F6F7F0',
  surfaceContainer: '#F0F1EA',
  surfaceContainerHigh: '#EAEBE4',
  outline:      '#73796E',
  outlineVariant: '#C3C8BB',
  white:        '#FFFFFF',
};
window.MC = MC;

// Inline SVG icon paths (Lucide-style, MIT). 24×24 viewBox, stroke-based.
// This is the design system's icon set — see ICONOGRAPHY in README.md.
const ICONS = {
  home:           '<path d="M15 21v-8a1 1 0 0 0-1-1h-4a1 1 0 0 0-1 1v8"/><path d="M3 10a2 2 0 0 1 .709-1.528l7-5.999a2 2 0 0 1 2.582 0l7 5.999A2 2 0 0 1 21 10v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/>',
  calendar_month: '<path d="M8 2v4"/><path d="M16 2v4"/><rect width="18" height="18" x="3" y="4" rx="2"/><path d="M3 10h18"/><circle cx="8" cy="14" r=".7"/><circle cx="12" cy="14" r=".7"/><circle cx="16" cy="14" r=".7"/><circle cx="8" cy="18" r=".7"/><circle cx="12" cy="18" r=".7"/>',
  event:          '<path d="M8 2v4"/><path d="M16 2v4"/><rect width="18" height="18" x="3" y="4" rx="2"/><path d="M3 10h18"/>',
  event_note:     '<rect width="18" height="18" x="3" y="4" rx="2"/><path d="M16 2v4"/><path d="M8 2v4"/><path d="M3 10h18"/><path d="M7 14h6"/><path d="M7 18h10"/>',
  history:        '<path d="M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"/><path d="M3 3v5h5"/><path d="M12 7v5l4 2"/>',
  help_outline:   '<circle cx="12" cy="12" r="10"/><path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3"/><path d="M12 17h.01"/>',
  group:          '<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/>',
  check_circle:   '<circle cx="12" cy="12" r="10"/><path d="m9 12 2 2 4-4"/>',
  check:          '<polyline points="20 6 9 17 4 12"/>',
  eco:            '<path d="M11 20A7 7 0 0 1 9.8 6.1C15.5 5 17 4.48 19.2 2.96a1 1 0 0 1 1.8.66 19 19 0 0 1-3.71 11.4A6.84 6.84 0 0 1 11 20Z"/><path d="M2 21c0-3 1.85-5.36 5.08-6"/>',
  visibility:     '<path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z"/><circle cx="12" cy="12" r="3"/>',
  logout:         '<path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/>',
  priority_high:  '<path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3"/><path d="M12 9v4"/><path d="M12 17h.01"/>',
  info:           '<circle cx="12" cy="12" r="10"/><path d="M12 16v-4"/><path d="M12 8h.01"/>',
  chevron_left:   '<path d="m15 18-6-6 6-6"/>',
  chevron_right:  '<path d="m9 18 6-6-6-6"/>',
  arrow_back:     '<line x1="19" y1="12" x2="5" y2="12"/><polyline points="12 19 5 12 12 5"/>',
  arrow_drop_down:'<path d="m6 9 6 6 6-6"/>',
  menu:           '<line x1="4" y1="12" x2="20" y2="12"/><line x1="4" y1="6" x2="20" y2="6"/><line x1="4" y1="18" x2="20" y2="18"/>',
  notifications:  '<path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9"/><path d="M10.3 21a1.94 1.94 0 0 0 3.4 0"/>',
  save:           '<path d="M15.2 3a2 2 0 0 1 1.4.6l3.8 3.8a2 2 0 0 1 .6 1.4V19a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2z"/><path d="M17 21v-7a1 1 0 0 0-1-1H8a1 1 0 0 0-1 1v7"/><path d="M7 3v4a1 1 0 0 0 1 1h7"/>',
  add_circle:     '<circle cx="12" cy="12" r="10"/><path d="M8 12h8"/><path d="M12 8v8"/>',
  schedule:       '<circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/>',
  storefront:     '<path d="m2 7 4.41-4.41A2 2 0 0 1 7.83 2h8.34a2 2 0 0 1 1.42.59L22 7"/><path d="M4 12v8a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-8"/><path d="M15 22v-4a2 2 0 0 0-2-2h-2a2 2 0 0 0-2 2v4"/><path d="M2 7h20"/>',
  sticky_note_2:  '<path d="M16 3H5a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h11l5-5V5a2 2 0 0 0-2-2z"/><path d="M15 3v6h6"/>',
  dashboard:      '<rect width="7" height="9" x="3" y="3" rx="1"/><rect width="7" height="5" x="14" y="3" rx="1"/><rect width="7" height="9" x="14" y="12" rx="1"/><rect width="7" height="5" x="3" y="16" rx="1"/>',
  analytics:      '<path d="M3 3v18h18"/><path d="m19 9-5 5-4-4-3 3"/>',
  mail:           '<rect width="20" height="16" x="2" y="4" rx="2"/><path d="m22 6-10 7L2 6"/>',
  settings:       '<circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z"/>',
  lock:           '<rect width="18" height="11" x="3" y="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/>',
  edit:           '<path d="M12 20h9"/><path d="M16.5 3.5a2.121 2.121 0 1 1 3 3L7 19l-4 1 1-4z"/>',
  bolt:           '<path d="M4 14a1 1 0 0 1-.78-1.63l9.9-10.2a.5.5 0 0 1 .86.46l-1.92 6.02A1 1 0 0 0 13 10h7a1 1 0 0 1 .78 1.63l-9.9 10.2a.5.5 0 0 1-.86-.46l1.92-6.02A1 1 0 0 0 11 14z"/>',
};

function Icon({ name, size = 20, color, style }) {
  const path = ICONS[name];
  if (!path) {
    // unknown icon — small text fallback so it's visible we missed one
    return <span style={{font:'10px monospace', color: '#B3261E', ...style}}>{name}</span>;
  }
  return (
    <svg
      width={size} height={size} viewBox="0 0 24 24"
      fill="none"
      stroke={color || 'currentColor'}
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      style={{ display: 'inline-block', flexShrink: 0, verticalAlign: 'middle', ...style }}
      dangerouslySetInnerHTML={{ __html: path }}
    />
  );
}

function FilledBtn({ children, color = MC.green, onClick, leading, full, size = 'md', danger }) {
  const bg = danger ? MC.red : color;
  const fg = '#fff';
  const pad = size === 'sm' ? '8px 16px' : '11px 24px';
  const font = size === 'sm' ? '500 13px/1 Roboto' : '500 14px/1 Roboto';
  return (
    <button onClick={onClick} style={{
      font, letterSpacing: 0.5, padding: pad, borderRadius: 9999,
      background: bg, color: fg, border: 'none', cursor: 'pointer',
      whiteSpace: 'nowrap', width: full ? '100%' : undefined,
      display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 8,
    }}>
      {leading && <Icon name={leading} size={size === 'sm' ? 16 : 18}/>}
      {children}
    </button>
  );
}

function OutlinedBtn({ children, onClick, leading, full, size = 'md', color }) {
  const stroke = color || MC.outline;
  const fg = color || MC.greenDark;
  const pad = size === 'sm' ? '7px 15px' : '10px 23px';
  const font = size === 'sm' ? '500 13px/1 Roboto' : '500 14px/1 Roboto';
  return (
    <button onClick={onClick} style={{
      font, letterSpacing: 0.5, padding: pad, borderRadius: 9999,
      background: 'transparent', color: fg, border: `1px solid ${stroke}`,
      cursor: 'pointer', whiteSpace: 'nowrap', width: full ? '100%' : undefined,
      display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 8,
    }}>
      {leading && <Icon name={leading} size={size === 'sm' ? 16 : 18}/>}
      {children}
    </button>
  );
}

function TextBtn({ children, onClick, leading, color }) {
  const fg = color || MC.greenDark;
  return (
    <button onClick={onClick} style={{
      font: '500 14px/1 Roboto', letterSpacing: 0.4, padding: '8px 12px',
      background: 'transparent', color: fg, border: 'none', borderRadius: 9999,
      cursor: 'pointer', whiteSpace: 'nowrap',
      display: 'inline-flex', alignItems: 'center', gap: 6,
    }}>
      {leading && <Icon name={leading} size={18}/>}
      {children}
    </button>
  );
}

function Card({ children, style }) {
  return (
    <div style={{
      background: MC.white, borderRadius: 12, padding: 20,
      boxShadow: '0 1px 2px rgba(0,0,0,0.04), 0 1px 3px rgba(0,0,0,0.04)',
      ...style,
    }}>{children}</div>
  );
}

function Badge({ kind, children }) {
  // kind: success | warning | error | info | neutral
  const map = {
    success: { bg: MC.greenSurface, fg: '#1B5E20', dot: MC.green },
    warning: { bg: MC.orangeSoft,   fg: '#7B3F00', dot: MC.orange },
    error:   { bg: MC.redSoft,      fg: '#410E0B', dot: MC.red },
    info:    { bg: MC.blueSoft,     fg: '#0D47A1', dot: MC.blue },
    neutral: { bg: MC.surfaceContainer, fg: MC.fg2, dot: MC.fg3 },
  };
  const c = map[kind] || map.neutral;
  return (
    <span style={{
      display: 'inline-flex', alignItems: 'center', gap: 6,
      padding: '4px 10px', borderRadius: 9999,
      background: c.bg, color: c.fg,
      font: '500 11px/1 Roboto', letterSpacing: 0.3,
      whiteSpace: 'nowrap', textTransform: 'uppercase',
    }}>
      <span style={{ width: 6, height: 6, borderRadius: '50%', background: c.dot }}/>
      {children}
    </span>
  );
}

function FormField({ label, children, hint, full }) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 6, width: full ? '100%' : undefined }}>
      <label style={{ font: '500 12px/1 Roboto', color: MC.fg2, letterSpacing: 0.3 }}>{label}</label>
      {children}
      {hint && <div style={{ font: '11px/1.4 Roboto', color: MC.fg3 }}>{hint}</div>}
    </div>
  );
}

function Select({ value, placeholder, full, dim }) {
  return (
    <div style={{
      padding: '10px 12px', border: `1px solid ${MC.outline}`, borderRadius: 4,
      font: '14px/1.2 Roboto', color: dim ? MC.fg3 : MC.fg1,
      background: MC.white, cursor: 'pointer',
      display: 'flex', justifyContent: 'space-between', alignItems: 'center',
      width: full ? '100%' : undefined, boxSizing: 'border-box',
    }}>
      <span>{value || placeholder}</span>
      <Icon name="arrow_drop_down" size={20} color={MC.fg2}/>
    </div>
  );
}

function Input({ value, placeholder, full, prefix }) {
  return (
    <div style={{
      padding: '10px 12px', border: `1px solid ${MC.outline}`, borderRadius: 4,
      font: '14px/1.2 Roboto', color: MC.fg1,
      background: MC.white,
      display: 'flex', alignItems: 'center', gap: 6,
      width: full ? '100%' : undefined, boxSizing: 'border-box',
    }}>
      {prefix && <Icon name={prefix} size={18} color={MC.fg2}/>}
      <span style={{flex:1}}>{value || <span style={{color:MC.fg3}}>{placeholder}</span>}</span>
    </div>
  );
}

function Textarea({ value, rows = 3 }) {
  return (
    <div style={{
      padding: '10px 12px', border: `1px solid ${MC.outline}`, borderRadius: 4,
      font: '14px/1.4 Roboto', color: MC.fg1,
      background: MC.white,
      minHeight: rows * 20,
    }}>{value}</div>
  );
}

function Checkbox({ checked, disabled, locked, children }) {
  return (
    <label style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '6px 0', cursor: disabled ? 'default' : 'pointer' }}>
      <span style={{
        width: 18, height: 18, minWidth: 18, borderRadius: 3,
        border: `2px solid ${checked ? MC.greenDark : MC.fg2}`,
        background: checked ? MC.greenDark : 'transparent',
        display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
      }}>
        {checked && <Icon name="check" size={14} color="#fff"/>}
      </span>
      <span style={{ font: '14px/1.3 Roboto', color: MC.fg1, opacity: disabled ? 0.7 : 1 }}>{children}</span>
      {locked && <Icon name="lock" size={14} color={MC.fg3}/>}
    </label>
  );
}

/* ─── App chrome (rail / top / bottom nav) ────────────────────────── */

function NavRail({ items, active, role }) {
  return (
    <div style={{
      width: 88, background: MC.surfaceLow, borderRight: `1px solid ${MC.outlineVariant}`,
      display: 'flex', flexDirection: 'column', alignItems: 'stretch',
      padding: '16px 0', gap: 4, flexShrink: 0,
    }}>
      <div style={{ display: 'flex', justifyContent: 'center', marginBottom: 12 }}>
        <img src="../assets/logo.svg" width="40" height="40" alt="Amap en Ligne"/>
      </div>
      <div style={{ font: '500 9px/1.2 Roboto', color: MC.fg3, textAlign: 'center', letterSpacing: 0.5, marginBottom: 8, textTransform: 'uppercase' }}>{role}</div>
      {items.map(it => {
        const on = it.key === active;
        return (
          <div key={it.key} style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', padding: '6px 4px', cursor: 'pointer' }}>
            <div style={{
              width: 56, height: 32, borderRadius: 16,
              background: on ? MC.greenSoft : 'transparent',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              color: on ? MC.greenDark : MC.fg2,
            }}>
              <Icon name={it.icon} size={22}/>
            </div>
            <div style={{ font: `${on ? 500 : 400} 11px/1.3 Roboto`, color: on ? MC.greenDark : MC.fg2, marginTop: 4, textAlign: 'center' }}>{it.label}</div>
          </div>
        );
      })}
    </div>
  );
}

function TopBar({ title, leading, trailing, breakpoint }) {
  return (
    <div style={{
      height: breakpoint === 'mobile' ? 56 : 64,
      background: MC.surface, borderBottom: `1px solid ${MC.outlineVariant}`,
      display: 'flex', alignItems: 'center', gap: 8, padding: '0 16px',
    }}>
      {leading}
      <div style={{ font: `500 ${breakpoint === 'mobile' ? 18 : 22}px/1.2 Roboto`, color: MC.fg1, flex: 1, marginLeft: leading ? 4 : 0 }}>{title}</div>
      {trailing}
    </div>
  );
}

function BottomNav({ items, active }) {
  return (
    <div style={{
      height: 80, background: MC.surfaceLow, borderTop: `1px solid ${MC.outlineVariant}`,
      display: 'flex', alignItems: 'stretch', justifyContent: 'space-around',
      padding: '12px 4px 16px',
    }}>
      {items.map(it => {
        const on = it.key === active;
        return (
          <div key={it.key} style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4, padding: '0 6px', flex: 1, cursor: 'pointer' }}>
            <div style={{
              padding: '4px 16px', borderRadius: 16,
              background: on ? MC.greenSoft : 'transparent',
            }}>
              <Icon name={it.icon} size={22} color={on ? MC.greenDark : MC.fg2}/>
            </div>
            <div style={{ font: `${on ? 500 : 400} 11px/1.2 Roboto`, color: on ? MC.greenDark : MC.fg2, textAlign: 'center' }}>{it.label}</div>
          </div>
        );
      })}
    </div>
  );
}

function AppShell({ breakpoint, title, role, navItems, activeNav, leadingAction, trailingAction, children, contentPadding }) {
  const isDesktop = breakpoint === 'desktop';
  const isMobile  = breakpoint === 'mobile';
  return (
    <div style={{ width: '100%', height: '100%', background: MC.surface, display: 'flex', flexDirection: 'row', overflow: 'hidden', fontFamily: 'Roboto, sans-serif' }}>
      {isDesktop && <NavRail items={navItems} active={activeNav} role={role}/>}
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', minWidth: 0 }}>
        <TopBar
          breakpoint={breakpoint}
          title={title}
          leading={!isDesktop ? (
            <button style={{ width: 40, height: 40, borderRadius: 9999, border: 'none', background: 'transparent', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <Icon name="menu" size={22} color={MC.fg1}/>
            </button>
          ) : leadingAction}
          trailing={trailingAction}
        />
        <div style={{ flex: 1, overflow: 'hidden', padding: contentPadding || (isMobile ? '16px' : '24px 32px'), background: MC.surface }}>
          {children}
        </div>
        {!isDesktop && <BottomNav items={navItems} active={activeNav}/>}
      </div>
    </div>
  );
}

Object.assign(window, {
  Icon, FilledBtn, OutlinedBtn, TextBtn, Card, Badge,
  FormField, Select, Input, Textarea, Checkbox,
  NavRail, TopBar, BottomNav, AppShell,
});
