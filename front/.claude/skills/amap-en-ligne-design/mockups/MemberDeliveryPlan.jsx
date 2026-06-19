// Member · Planning des livraisons
//
// Renders the screen at one of: 'desktop' | 'tablet' | 'mobile'.
// Source spec: documentation/feature/fr/ui/member/screen-member-02-delivery-plan.md

const MEMBER_NAV = [
  { key: 'home',     icon: 'home',            label: 'Accueil' },
  { key: 'planning', icon: 'calendar_month',  label: 'Planning' },
  { key: 'history',  icon: 'history',         label: 'Historique' },
  { key: 'help',     icon: 'help_outline',    label: 'Aide' },
];

const DELIVERIES = [
  {
    id: 1, date: 'Mercredi 3 janvier', time: '18h00 – 20h00',
    producers: ['Maraîcher Bio', 'Œufs Fermiers'],
    state: 'past', participated: true,
    volunteers: ['Marie D.', 'Jean P.', 'Paul M.', 'Lisa K.', 'Tom V.'],
  },
  {
    id: 2, date: 'Mercredi 10 janvier', time: '18h00 – 20h00',
    producers: ['Maraîcher Bio', 'Pain Artisanal'],
    state: 'enrolled', filled: 5, total: 5,
  },
  {
    id: 3, date: 'Mercredi 17 janvier', time: '18h00 – 20h00',
    producers: ['Maraîcher Bio', 'Œufs Fermiers'],
    state: 'urgent', filled: 2, total: 5,
  },
  {
    id: 4, date: 'Mercredi 24 janvier', time: '18h00 – 20h00',
    producers: ['Maraîcher Bio', 'Pain Artisanal'],
    state: 'limited', filled: 3, total: 5,
  },
  {
    id: 5, date: 'Mercredi 31 janvier', time: '18h00 – 20h00',
    producers: ['Maraîcher Bio', 'Légumes de saison'],
    state: 'early', filled: 1, total: 5,
    earlySlot: { time: '17h00 – 20h00', explanation: 'Réception des légumes du maraîcher.' },
    standardTime: '18h00 – 20h00',
  },
];

function MonthNav({ breakpoint }) {
  const isMobile = breakpoint === 'mobile';
  return (
    <div style={{
      display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      padding: isMobile ? '12px 4px' : '8px 0', marginBottom: 16,
      gap: 8,
    }}>
      <OutlinedBtn leading="chevron_left" size={isMobile ? 'sm' : 'md'}>
        {isMobile ? 'Déc' : 'Décembre 2024'}
      </OutlinedBtn>
      <div style={{ font: `500 ${isMobile ? 18 : 22}px/1.2 Roboto`, color: MC.fg1 }}>Janvier 2025</div>
      <OutlinedBtn size={isMobile ? 'sm' : 'md'}>
        {isMobile ? 'Fév' : 'Février 2025'} <Icon name="chevron_right" size={18}/>
      </OutlinedBtn>
    </div>
  );
}

function VolunteerCounter({ filled, total, kind = 'neutral', extra }) {
  const slots = [];
  for (let i = 0; i < total; i++) {
    const on = i < filled;
    slots.push(
      <span key={i} style={{
        width: 14, height: 14, borderRadius: '50%',
        background: on ? (kind === 'error' ? MC.red : kind === 'warning' ? MC.orange : MC.green) : MC.surfaceContainerHigh,
        border: `1px solid ${MC.outlineVariant}`,
      }}/>
    );
  }
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
      <Icon name="group" size={18} color={MC.fg2}/>
      <div style={{ display: 'flex', gap: 4 }}>{slots}</div>
      <span style={{ font: '500 13px/1 Roboto', color: MC.fg1 }}>{filled}/{total} bénévoles</span>
      {extra && <span style={{ font: '13px/1 Roboto', color: MC.fg2 }}>· {extra}</span>}
    </div>
  );
}

function DeliveryCard({ d, breakpoint }) {
  const isMobile = breakpoint === 'mobile';
  const titleSize = isMobile ? 16 : 18;
  return (
    <Card style={{ padding: isMobile ? 16 : 20 }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', gap: 12, alignItems: 'flex-start', flexWrap: 'wrap' }}>
        <div style={{flex:1, minWidth: 0}}>
          <div style={{ display: 'flex', gap: 10, alignItems: 'center' }}>
            <Icon name="event" size={20} color={MC.greenDark}/>
            <div style={{ font: `500 ${titleSize}px/1.3 Roboto`, color: MC.fg1 }}>{d.date}</div>
          </div>
          <div style={{ font: '14px/1.4 Roboto', color: MC.fg2, marginLeft: 30, marginTop: 2 }}>{d.time}</div>
        </div>
        {d.state === 'past'     && <Badge kind="neutral">Terminé</Badge>}
        {d.state === 'enrolled' && <Badge kind="success">Inscrit · Complet</Badge>}
        {d.state === 'urgent'   && <Badge kind="error">Besoin urgent</Badge>}
        {d.state === 'limited'  && <Badge kind="warning">Places limitées</Badge>}
        {d.state === 'early'    && <Badge kind="info">Créneau anticipé</Badge>}
      </div>

      <div style={{
        marginTop: 12, marginLeft: 30,
        display: 'flex', flexWrap: 'wrap', gap: 6,
      }}>
        {d.producers.map((p, i) => (
          <span key={i} style={{
            display: 'inline-flex', alignItems: 'center', gap: 6,
            padding: '4px 10px', borderRadius: 6,
            background: MC.greenSurface, color: '#1B5E20',
            font: '13px/1.3 Roboto',
          }}>
            <Icon name="eco" size={14}/> {p}
          </span>
        ))}
      </div>

      <div style={{ height: 1, background: MC.outlineVariant, margin: '14px 0' }}/>

      {d.state === 'past' ? (
        <div>
          <div style={{ font: '13px/1.4 Roboto', color: MC.fg2, marginBottom: 6, display: 'flex', alignItems: 'center', gap: 6 }}>
            <Icon name="check_circle" size={16} color={MC.green}/>
            <span style={{color: MC.fg1, fontWeight: 500}}>Vous avez participé.</span>
            Bénévoles présents :
          </div>
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6 }}>
            {d.volunteers.map((v, i) => (
              <span key={i} style={{
                padding: '4px 10px', borderRadius: 9999,
                background: MC.surfaceContainer, font: '12px/1 Roboto', color: MC.fg2,
              }}>{v}</span>
            ))}
          </div>
        </div>
      ) : d.state === 'enrolled' ? (
        <div>
          <VolunteerCounter filled={d.filled} total={d.total} kind="success" extra="Complet"/>
          <div style={{ display: 'flex', gap: 8, marginTop: 12, flexWrap: 'wrap' }}>
            <OutlinedBtn leading="visibility">Voir détails</OutlinedBtn>
            <OutlinedBtn leading="logout" color={MC.red}>Se désinscrire</OutlinedBtn>
          </div>
        </div>
      ) : d.state === 'urgent' ? (
        <div>
          <VolunteerCounter filled={d.filled} total={d.total} kind="error" extra={`Manque ${d.total - d.filled}`}/>
          <div style={{ marginTop: 12 }}>
            <FilledBtn leading="priority_high" danger full={isMobile}>S'inscrire maintenant</FilledBtn>
          </div>
        </div>
      ) : d.state === 'limited' ? (
        <div>
          <VolunteerCounter filled={d.filled} total={d.total} kind="warning" extra={`${d.total - d.filled} places restantes`}/>
          <div style={{ marginTop: 12 }}>
            <FilledBtn full={isMobile}>S'inscrire</FilledBtn>
          </div>
        </div>
      ) : d.state === 'early' ? (
        <div>
          <VolunteerCounter filled={d.filled} total={d.total}/>
          <div style={{ font: '13px/1.4 Roboto', color: MC.fg2, marginTop: 4 }}>Choisissez votre créneau :</div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 12, marginTop: 12 }}>
            <FilledBtn full>S'inscrire · Créneau standard {d.standardTime}</FilledBtn>
            <div>
              <FilledBtn color={MC.blue} full>
                S'inscrire · Créneau anticipé {d.earlySlot.time}
              </FilledBtn>
              <div style={{ font: '12px/1.4 Roboto', color: MC.fg2, marginTop: 8, display: 'flex', gap: 6, alignItems: 'flex-start', paddingLeft: 4 }}>
                <Icon name="info" size={14} color={MC.blue} style={{marginTop:1}}/>
                {d.earlySlot.explanation}
              </div>
            </div>
          </div>
        </div>
      ) : null}
    </Card>
  );
}

function MemberDeliveryPlan({ breakpoint }) {
  const isMobile  = breakpoint === 'mobile';
  const isDesktop = breakpoint === 'desktop';
  return (
    <AppShell
      breakpoint={breakpoint}
      title="Planning des livraisons"
      role="Amapien"
      navItems={MEMBER_NAV}
      activeNav="planning"
      leadingAction={isDesktop ? (
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginRight: 8 }}>
          <Icon name="calendar_month" size={22} color={MC.greenDark}/>
        </div>
      ) : null}
      trailingAction={
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <button style={{ width: 40, height: 40, borderRadius: 9999, border: 'none', background: 'transparent', cursor: 'pointer' }}>
            <Icon name="notifications" size={22} color={MC.fg2}/>
          </button>
          <div style={{
            width: 36, height: 36, borderRadius: '50%', background: MC.greenSoft,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            font: '500 14px/1 Roboto', color: MC.greenDark,
          }}>MD</div>
        </div>
      }
    >
      <div style={{
        maxWidth: isDesktop ? 880 : '100%', margin: '0 auto',
        height: '100%', overflow: 'auto',
      }}>
        <MonthNav breakpoint={breakpoint}/>

        <div style={{
          display: 'flex', alignItems: 'baseline', justifyContent: 'space-between',
          marginBottom: 12,
        }}>
          <div style={{ font: '500 14px/1 Roboto', color: MC.greenDark, letterSpacing: 0.5, textTransform: 'uppercase' }}>
            Livraisons ce mois
          </div>
          <div style={{ font: '13px/1 Roboto', color: MC.fg2 }}>5 créneaux</div>
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          {DELIVERIES.map(d => <DeliveryCard key={d.id} d={d} breakpoint={breakpoint}/>)}
        </div>

        <div style={{ height: 24 }}/>
      </div>
    </AppShell>
  );
}

window.MemberDeliveryPlan = MemberDeliveryPlan;
