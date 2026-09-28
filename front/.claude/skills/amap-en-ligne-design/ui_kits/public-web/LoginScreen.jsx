function LoginScreen({ go }) {
  const C = window.AmapColors;
  const [email, setEmail] = React.useState('');
  const [password, setPassword] = React.useState('');
  const [submitting, setSubmitting] = React.useState(false);
  const [error, setError] = React.useState(null);

  const submit = () => {
    setError(null);
    if (!email || !email.includes('@')) { setError('email'); return; }
    if (!password || password.length < 6) { setError('password'); return; }
    setSubmitting(true);
    setTimeout(() => {
      setSubmitting(false);
      setError('credentials');
    }, 900);
  };

  return (
    <MobileFrame title="Connexion" onBack={() => go('/')}>
      <div style={{maxWidth: 400, margin: '0 auto', padding: '32px 24px'}}>
        <div style={{font:'400 22px/1.27 Roboto', color: C.fg1, marginBottom: 24}}>
          Connexion à votre compte
        </div>

        <div style={{display:'flex',flexDirection:'column',gap:16}}>
          <TextField
            label="Email"
            value={email}
            onChange={setEmail}
            error={error === 'email' ? "Saisissez un email valide." : null}
          />
          <TextField
            label="Mot de passe"
            type="password"
            value={password}
            onChange={setPassword}
            error={error === 'password' ? "Le mot de passe doit contenir au moins 6 caractères." : null}
          />
          <TextField
            label="Serveur"
            value="AMAP des Collines"
            readOnly
            onClick={() => alert('Server picker — secondary UI')}
            trailing={<span className="material-symbols-outlined" style={{color: C.fg2}}>chevron_right</span>}
          />

          {error === 'credentials' && (
            <div style={{font:'14px/1.4 Roboto', color: C.error, textAlign:'center'}}>
              Email ou mot de passe incorrect.
            </div>
          )}

          <div style={{marginTop: 8}}>
            <FilledButton color={C.green} full loading={submitting} onClick={submit}>
              SE CONNECTER
            </FilledButton>
          </div>

          <div style={{height:1, background: C.outlineVariant, margin: '8px 0'}}/>

          <div style={{textAlign:'center'}}>
            <TextButton onClick={() => alert('Forgot password flow')}>Mot de passe oublié ?</TextButton>
          </div>

          <div style={{height:1, background: C.outlineVariant, margin: '4px 0'}}/>

          <div style={{font:'12px/1.4 Roboto', color: C.fg2, textAlign:'center'}}>
            Première connexion ? Vous devez avoir reçu une invitation par email de votre coordinateur.
          </div>
          <div style={{font:'12px/1.4 Roboto', color: C.fg2, textAlign:'center'}}>
            Pas d'invitation ? Contactez votre organisation ou créez une nouvelle organisation depuis la page d'accueil.
          </div>
        </div>
      </div>
    </MobileFrame>
  );
}

window.LoginScreen = LoginScreen;
