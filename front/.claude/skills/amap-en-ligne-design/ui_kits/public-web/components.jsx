// Shared atoms — Material 3-ish recreations of Flutter widgets.
// Load order: React 18 → babel-standalone → this file → screen files → App → index.

const C = {
  green: '#4CAF50',
  blue: '#2196F3',
  orange: '#FF9800',
  primary: '#386A20',
  primaryContainer: '#B7F397',
  onPrimaryContainer: '#042100',
  surface: '#FCFDF6',
  surfaceLow: '#F6F7F0',
  surfaceContainer: '#F0F1EA',
  outline: '#73796E',
  outlineVariant: '#C3C8BB',
  fg1: '#1A1C18',
  fg2: '#43483E',
  fg3: '#73796E',
  error: '#B3261E',
  errorContainer: '#F9DEDC',
};

window.AmapColors = C;

function FilledButton({ children, color = C.green, onClick, disabled, full, loading }) {
  const bg = disabled ? '#0000001F' : color;
  const fg = disabled ? '#0000005C' : '#fff';
  return (
    <button
      onClick={disabled ? undefined : onClick}
      style={{
        font: '500 14px/1 Roboto',
        letterSpacing: 0.5,
        padding: '11px 24px',
        borderRadius: 9999,
        background: bg,
        color: fg,
        border: 'none',
        cursor: disabled ? 'not-allowed' : 'pointer',
        width: full ? '100%' : undefined,
        minHeight: 40,
        whiteSpace: 'nowrap',
        display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 8,
      }}
    >
      {loading
        ? <span style={{width:16,height:16,border:'2px solid #fff',borderRightColor:'transparent',borderRadius:'50%',display:'inline-block',animation:'amap-spin 0.9s linear infinite'}}/>
        : children}
    </button>
  );
}

function OutlinedButton({ children, onClick, disabled, full }) {
  return (
    <button
      onClick={disabled ? undefined : onClick}
      style={{
        font: '500 14px/1 Roboto',
        letterSpacing: 0.5,
        padding: '10px 23px',
        borderRadius: 9999,
        background: 'transparent',
        color: disabled ? '#0000005C' : C.primary,
        border: `1px solid ${disabled ? '#0000001F' : C.outline}`,
        cursor: disabled ? 'not-allowed' : 'pointer',
        width: full ? '100%' : undefined,
        minHeight: 40,
      }}
    >
      {children}
    </button>
  );
}

function TextButton({ children, onClick, color = C.primary }) {
  return (
    <button
      onClick={onClick}
      style={{
        font: '500 14px/1 Roboto',
        letterSpacing: 0.5,
        padding: '10px 12px',
        borderRadius: 9999,
        background: 'transparent',
        color,
        border: 'none',
        cursor: 'pointer',
      }}
    >{children}</button>
  );
}

function TextField({ label, value, onChange, type = 'text', trailing, onClick, readOnly, error }) {
  const [focused, setFocused] = React.useState(false);
  const filled = (value !== undefined && value !== null && value !== '') || focused;
  const borderColor = error ? C.error : focused ? C.primary : C.outline;
  return (
    <div
      onClick={onClick}
      style={{ position: 'relative', cursor: onClick ? 'pointer' : 'text' }}
    >
      <div style={{
        position: 'absolute',
        left: 12,
        top: filled ? -7 : 14,
        background: focused || filled ? C.surface : 'transparent',
        padding: filled ? '0 4px' : 0,
        font: `${filled ? 12 : 16}px/1 Roboto`,
        color: error ? C.error : focused ? C.primary : C.fg2,
        pointerEvents: 'none',
        transition: 'top 0.12s, font-size 0.12s',
      }}>{label}</div>
      {readOnly ? (
        <div style={{
          padding: '14px 12px',
          border: `1px solid ${borderColor}`,
          borderRadius: 4,
          font: '16px/1.2 Roboto',
          color: C.fg1,
          minHeight: 26,
          display: 'flex', alignItems: 'center', justifyContent: 'space-between'
        }}>
          <span>{value}</span>
          {trailing}
        </div>
      ) : (
        <input
          type={type}
          value={value || ''}
          onChange={(e) => onChange?.(e.target.value)}
          onFocus={() => setFocused(true)}
          onBlur={() => setFocused(false)}
          style={{
            width: '100%',
            boxSizing: 'border-box',
            padding: focused ? '13px 11px' : '14px 12px',
            border: `${focused ? 2 : 1}px solid ${borderColor}`,
            borderRadius: 4,
            font: '16px/1.2 Roboto',
            background: 'transparent',
            outline: 'none',
            color: C.fg1,
          }}
        />
      )}
      {error && <div style={{font:'12px/1.3 Roboto', color: C.error, marginTop: 4, paddingLeft: 12}}>{error}</div>}
    </div>
  );
}

function SectionHeader({ children }) {
  return (
    <div style={{
      font: '500 14px/1 Roboto',
      letterSpacing: 0.5,
      color: C.primary,
      textTransform: 'uppercase',
      margin: '12px 0 4px',
    }}>{children}</div>
  );
}

function AppBar({ title, onBack }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 12,
      padding: '0 4px', height: 56, background: C.surface,
      borderBottom: 'none',
    }}>
      {onBack && (
        <button onClick={onBack} style={{
          width: 40, height: 40, borderRadius: 9999, border: 'none', background: 'transparent',
          cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', marginLeft: 4
        }}>
          <span className="material-symbols-outlined" style={{fontSize: 22, color: C.fg1}}>arrow_back</span>
        </button>
      )}
      <div style={{ font: '500 20px/1.2 Roboto', color: C.fg1, marginLeft: onBack ? 0 : 16 }}>{title}</div>
    </div>
  );
}

function MobileFrame({ children, title, onBack }) {
  return (
    <div style={{
      background: C.surface,
      borderRadius: 28,
      overflow: 'hidden',
      width: 412,
      minHeight: 760,
      maxHeight: '92vh',
      boxShadow: '0 20px 60px rgba(0,0,0,0.18), 0 4px 12px rgba(0,0,0,0.08)',
      border: `8px solid #1A1C18`,
      display: 'flex', flexDirection: 'column',
    }}>
      <div style={{height: 28, background: C.surface, display:'flex',alignItems:'center',justifyContent:'space-between',padding:'0 18px',font:'500 13px/1 Roboto',color: C.fg1}}>
        <span>9:41</span>
        <span style={{display:'flex',gap:8,fontSize:11,letterSpacing:1}}>
          <span>•••</span><span>5G</span><span>100%</span>
        </span>
      </div>
      {title !== undefined && <AppBar title={title} onBack={onBack}/>}
      <div style={{flex: 1, overflow: 'auto'}}>{children}</div>
    </div>
  );
}

function Card({ children, style }) {
  return (
    <div style={{
      background: '#FFFFFF',
      borderRadius: 12,
      padding: 16,
      boxShadow: '0 1px 2px rgba(0,0,0,0.04), 0 1px 3px rgba(0,0,0,0.04)',
      ...style,
    }}>{children}</div>
  );
}

function SegmentedButton({ options, value, onChange }) {
  return (
    <div style={{display:'inline-flex',borderRadius:9999,overflow:'hidden',border:`1px solid ${C.outline}`,width:'100%'}}>
      {options.map((opt, i) => {
        const on = value === opt.value;
        return (
          <button key={opt.value}
            onClick={() => onChange(opt.value)}
            style={{
              flex: 1,
              font: '500 14px/1 Roboto',
              letterSpacing: 0.4,
              padding: '11px 16px',
              background: on ? C.primaryContainer : 'transparent',
              color: on ? C.onPrimaryContainer : C.fg1,
              border: 'none',
              borderLeft: i === 0 ? 'none' : `1px solid ${C.outline}`,
              cursor: 'pointer',
              display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 6,
            }}>
            {on && <span className="material-symbols-outlined" style={{fontSize:18}}>check</span>}
            {opt.label}
          </button>
        );
      })}
    </div>
  );
}

function CheckboxTile({ checked, onChange, children }) {
  return (
    <label style={{display:'flex',gap:12,alignItems:'flex-start',cursor:'pointer',padding:'6px 0'}}>
      <span style={{
        width:20,height:20,minWidth:20,
        border:`2px solid ${checked ? C.primary : C.fg2}`,
        background: checked ? C.primary : 'transparent',
        borderRadius:3,marginTop:2,
        display:'inline-flex',alignItems:'center',justifyContent:'center',
      }}>
        {checked && <span className="material-symbols-outlined" style={{fontSize:16,color:'#fff'}}>check</span>}
      </span>
      <span onClick={() => onChange(!checked)} style={{font:'14px/1.4 Roboto', color: C.fg1}}>{children}</span>
    </label>
  );
}

Object.assign(window, {
  FilledButton, OutlinedButton, TextButton, TextField, SectionHeader, AppBar, MobileFrame, Card, SegmentedButton, CheckboxTile,
});
