function App() {
  const [route, setRoute] = React.useState('/');
  const [query, setQuery] = React.useState({});

  const go = (path) => {
    const [base, qs] = path.split('?');
    const q = {};
    if (qs) qs.split('&').forEach(p => { const [k,v] = p.split('='); q[k] = decodeURIComponent(v || ''); });
    setRoute(base);
    setQuery(q);
    window.scrollTo(0, 0);
  };

  return (
    <div data-screen-label={
      route === '/' ? 'Home' :
      route === '/login' ? 'Login' :
      route === '/register' ? 'Register' :
      route === '/amap-search' ? 'Search' : route
    }>
      {route === '/' && <HomeScreen go={go}/>}
      {route === '/login' && <LoginScreen go={go}/>}
      {route === '/register' && <RegisterScreen go={go}/>}
      {route === '/amap-search' && <SearchScreen go={go} preselectedOrg={query.org}/>}
    </div>
  );
}

window.App = App;
