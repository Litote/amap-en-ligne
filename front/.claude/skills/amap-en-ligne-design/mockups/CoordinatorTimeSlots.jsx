// Coordinator · Gestion des livraisons
//
// Source spec: documentation/feature/fr/ui/coordinator/screen-coordinator-02-time-slots.md

const COORD_NAV = [
  { key: 'dashboard', icon: 'dashboard',      label: 'Dashboard' },
  { key: 'slots',     icon: 'schedule',       label: 'Créneaux' },
  { key: 'stats',     icon: 'analytics',      label: 'Stats' },
  { key: 'comms',     icon: 'mail',           label: 'Comms' },
  { key: 'settings',  icon: 'settings',       label: 'Paramètres' },
];

const EXISTING = [
  { id: 1, date: '17 Jan',  time: '18h – 20h', filled: 2, total: 5, kind: 'error',   label: 'Critique',     actions: ['MODIFIER', 'SUPPRIMER', 'RELANCER'] },
  { id: 2, date: '24 Jan',  time: '18h – 20h', filled: 3, total: 5, kind: 'warning', label: 'À surveiller', actions: ['MODIFIER', 'SUPPRIMER', 'ENVOYER RAPPEL'] },
  { id: 3, date: '31 Jan',  time: '18h – 20h', filled: 0, total: 5, kind: 'info',    label: 'Nouveau',      actions: ['MODIFIER', 'SUPPRIMER', 'PUBLIER'] },
];

function FormSection({ title, icon, children }) {
  return (
    <div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 12 }}>
        {icon && <Icon name={icon} size={18} color={MC.greenDark}/>}
        <div style={{ font: '500 13px/1 Roboto', color: MC.greenDark, letterSpacing: 0.5, textTransform: 'uppercase' }}>{title}</div>
      </div>
      {children}
    </div>
  );
}

function EarlySlotPanel({ breakpoint }) {
  const isMobile = breakpoint === 'mobile';
  return (
    <div style={{
      border: `1px dashed ${MC.outline}`, borderRadius: 8,
      padding: 16, background: MC.blueSoft + '40',
      display: 'flex', flexDirection: 'column', gap: 12,
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
        <Icon name="bolt" size={18} color={MC.blue}/>
        <div style={{ font: '500 13px/1 Roboto', color: MC.fg1, letterSpacing: 0.4, textTransform: 'uppercase' }}>Créneau anticipé</div>
        <span style={{
          font: '500 10px/1 Roboto', padding: '3px 8px', borderRadius: 4,
          background: MC.surfaceContainer, color: MC.fg2, letterSpacing: 0.3,
        }}>HÉRITÉ DU TEMPLATE</span>
      </div>
      <div style={{
        display: 'grid',
        gridTemplateColumns: isMobile ? '1fr' : '160px 1fr 120px',
        gap: 12,
      }}>
        <FormField label="Heure d'arrivée">
          <Input value="17:00" prefix="schedule"/>
        </FormField>
        <FormField label="Explication">
          <Input value="Réception des légumes du maraîcher" />
        </FormField>
        <FormField label="Max volontaires">
          <Input value="2" prefix="group"/>
        </FormField>
      </div>
      <TextBtn leading="edit">Modifier pour cette livraison uniquement</TextBtn>
    </div>
  );
}

function ExistingSlotRow({ s, breakpoint }) {
  const isMobile = breakpoint === 'mobile';
  return (
    <div style={{
      display: 'flex', flexDirection: isMobile ? 'column' : 'row',
      gap: 12, padding: '14px 16px',
      borderTop: `1px solid ${MC.outlineVariant}`,
      alignItems: isMobile ? 'stretch' : 'center',
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, flex: 1 }}>
        <div style={{
          width: 48, height: 48, borderRadius: 8, background: MC.surfaceContainer,
          display: 'flex', alignItems: 'center', justifyContent: 'center', flexDirection: 'column',
          flexShrink: 0,
        }}>
          <div style={{ font: '500 11px/1 Roboto', color: MC.fg2 }}>{s.date.split(' ')[1].toUpperCase()}</div>
          <div style={{ font: '700 18px/1 Roboto', color: MC.fg1 }}>{s.date.split(' ')[0]}</div>
        </div>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ font: '500 14px/1.3 Roboto', color: MC.fg1 }}>{s.time}</div>
          <div style={{ display: 'flex', gap: 10, alignItems: 'center', marginTop: 4 }}>
            <span style={{ font: '13px/1 Roboto', color: MC.fg2 }}>{s.filled}/{s.total} bénévoles</span>
            <Badge kind={s.kind}>{s.label}</Badge>
          </div>
        </div>
      </div>
      <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
        {s.actions.map((a, i) => {
          if (a === 'SUPPRIMER') return <OutlinedBtn key={i} size="sm" color={MC.red}>{a}</OutlinedBtn>;
          if (i === s.actions.length - 1) return <FilledBtn key={i} size="sm" color={s.kind === 'error' ? MC.red : s.kind === 'info' ? MC.greenDark : MC.greenDark}>{a}</FilledBtn>;
          return <OutlinedBtn key={i} size="sm">{a}</OutlinedBtn>;
        })}
      </div>
    </div>
  );
}

function NewSlotForm({ breakpoint }) {
  const isMobile = breakpoint === 'mobile';
  return (
    <Card style={{ padding: isMobile ? 16 : 24 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 20 }}>
        <Icon name="add_circle" size={22} color={MC.greenDark}/>
        <div style={{ font: '500 18px/1.2 Roboto', color: MC.fg1 }}>Nouveau créneau</div>
      </div>

      <div style={{ display: 'flex', flexDirection: 'column', gap: 20 }}>
        <FormSection title="Date et template" icon="event">
          <div style={{
            display: 'grid',
            gridTemplateColumns: isMobile ? '1fr' : '200px 1fr',
            gap: 12,
          }}>
            <FormField label="Date de livraison">
              <Select value="31/01/2025" full/>
            </FormField>
            <FormField label="Template" hint="Les templates sont gérés par l'admin de l'organisation.">
              <Select value="Livraison avec réception anticipée" full/>
            </FormField>
          </div>
        </FormSection>

        <FormSection title="Horaires" icon="schedule">
          <div style={{
            display: 'grid',
            gridTemplateColumns: isMobile ? '1fr 1fr' : '160px 160px',
            gap: 12,
          }}>
            <FormField label="Début">
              <Select value="18:00" full/>
            </FormField>
            <FormField label="Fin">
              <Select value="20:00" full/>
            </FormField>
          </div>
        </FormSection>

        <EarlySlotPanel breakpoint={breakpoint}/>

        <FormSection title="Bénévoles requis" icon="group">
          <div style={{
            display: 'grid',
            gridTemplateColumns: isMobile ? '1fr 1fr' : '160px 160px',
            gap: 12,
          }}>
            <FormField label="Minimum">
              <Select value="5" full/>
            </FormField>
            <FormField label="Maximum">
              <Select value="8" full/>
            </FormField>
          </div>
        </FormSection>

        <FormSection title="Producteurs présents" icon="storefront">
          <div style={{
            display: 'grid',
            gridTemplateColumns: isMobile ? '1fr' : '1fr 1fr',
            gap: '0px 12px',
          }}>
            <Checkbox checked disabled locked>Maraîcher Bio · obligatoire</Checkbox>
            <Checkbox>Œufs Fermiers</Checkbox>
            <Checkbox>Pain Artisanal</Checkbox>
            <Checkbox>Fromage de chèvre</Checkbox>
          </div>
        </FormSection>

        <FormSection title="Instructions spéciales" icon="sticky_note_2">
          <Textarea value="Prévoir contenants supplémentaires pour les nouvelles conserves de saison." rows={3}/>
        </FormSection>

        <div style={{
          display: 'flex', justifyContent: 'flex-end', gap: 12,
          paddingTop: 8, borderTop: `1px solid ${MC.outlineVariant}`,
        }}>
          <OutlinedBtn>Annuler</OutlinedBtn>
          <FilledBtn leading="check">Créer le créneau</FilledBtn>
        </div>
      </div>
    </Card>
  );
}

function ExistingSlotsCard({ breakpoint }) {
  return (
    <Card style={{ padding: 0, overflow: 'hidden' }}>
      <div style={{ padding: '16px 20px', display: 'flex', alignItems: 'center', gap: 10 }}>
        <Icon name="event_note" size={22} color={MC.greenDark}/>
        <div style={{ font: '500 18px/1.2 Roboto', color: MC.fg1, flex: 1 }}>Créneaux existants</div>
        <span style={{ font: '13px/1 Roboto', color: MC.fg2 }}>{EXISTING.length} créneaux</span>
      </div>
      {EXISTING.map(s => <ExistingSlotRow key={s.id} s={s} breakpoint={breakpoint}/>)}
    </Card>
  );
}

function CoordinatorTimeSlots({ breakpoint }) {
  const isMobile  = breakpoint === 'mobile';
  const isDesktop = breakpoint === 'desktop';
  return (
    <AppShell
      breakpoint={breakpoint}
      title="Gestion des livraisons"
      role="Coordinateur"
      navItems={COORD_NAV}
      activeNav="slots"
      leadingAction={isDesktop ? (
        <OutlinedBtn size="sm" leading="arrow_back">Dashboard</OutlinedBtn>
      ) : null}
      trailingAction={
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          {!isMobile && <OutlinedBtn size="sm" leading="save">Sauvegarder</OutlinedBtn>}
          {isMobile && <button style={{ width: 40, height: 40, borderRadius: 9999, border: 'none', background: 'transparent', cursor: 'pointer' }}><Icon name="save" size={22} color={MC.fg1}/></button>}
        </div>
      }
    >
      <div style={{
        maxWidth: isDesktop ? 1100 : '100%', margin: '0 auto',
        height: '100%', overflow: 'auto',
        display: 'grid',
        gridTemplateColumns: isDesktop ? '1fr 380px' : '1fr',
        gap: isDesktop ? 24 : 16,
        alignItems: 'start',
      }}>
        <NewSlotForm breakpoint={breakpoint}/>
        <ExistingSlotsCard breakpoint={breakpoint}/>
      </div>
    </AppShell>
  );
}

window.CoordinatorTimeSlots = CoordinatorTimeSlots;
