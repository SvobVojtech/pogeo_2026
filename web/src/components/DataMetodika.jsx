import { useReveal } from '../hooks/useReveal'

const PREDICTORS = [
  { code: 'VZDELANI_VYSOKO',  label: 'Podíl VŠ vzdělaných',           dir: '↑', positive: true },
  { code: 'VZDELANI_STR_BEZ', label: 'Podíl vyučených bez maturity',  dir: '↓', positive: false },
  { code: 'NEPRAC_DUCH',      label: 'Podíl nepracujících důchodců',  dir: '↓', positive: false },
  { code: 'PODNIKATELE',      label: 'Podíl podnikatelů / OSVČ',      dir: '↑', positive: true },
  { code: 'NEZAMEST',         label: 'Míra nezaměstnanosti',          dir: '↓', positive: false },
  { code: 'VERICI',           label: 'Podíl věřících',                dir: '↓', positive: false },
]

export default function DataMetodika() {
  const ref = useReveal()

  return (
    <section id="data-metodika" ref={ref}>
      <div className="container">
        <div className="section-label">04 — Data a metodika</div>
        <h2 className="section-title reveal">
          Data <span className="gold">&amp;</span> prediktory
        </h2>
        <p className="section-lead reveal delay-1">
          6 prediktorů ze Sčítání lidu, domů a bytů 2021 (SLDB) — vybraných
          na základě korelační analýzy a teorií volebního chování.
        </p>

        <div className="two-col">
          <div>
            <h3 className="reveal grotesk" style={{ fontSize: '1.05rem', marginBottom: '1rem', color: 'var(--gold)' }}>
              Datové zdroje
            </h3>
            {[
              { title: 'Volební data', text: 'ČSÚ GPKG — volby do PSP ČR 2025. Proměnná: podíl platných hlasů pro Piráty (%). Ověřeno z volby.cz — Praha: 16,85 % ✓' },
              { title: 'Sociodemografické prediktory', text: 'SLDB 2021 — 17 indikátorů na úrovni LAU2. Po korelační analýze a VIF testu zvoleno 6 prediktorů. Všechny proměnné v % — podíly z celkové populace.' },
              { title: 'Prostorová vrstva', text: 'Polygony obcí ČR — S-JTSK / Krovak East North (EPSG:5514). Metrický CRS vhodný pro GWR. Filtrace: 4 vojenské újezdy + 97 obcí < 50 voličů odstraněno.' },
            ].map(({ title, text }, i) => (
              <div key={i} className={`card reveal delay-${i + 1}`} style={{ marginBottom: '1rem' }}>
                <div className="card-label">{title}</div>
                <p style={{ fontSize: '0.87rem', color: 'var(--dim)', margin: 0, lineHeight: 1.6 }}>{text}</p>
              </div>
            ))}
          </div>

          <div>
            <h3 className="reveal grotesk" style={{ fontSize: '1.05rem', marginBottom: '1rem', color: 'var(--gold)' }}>
              Vybrané prediktory
            </h3>
            <div className="table-wrap reveal delay-1">
              <table>
                <thead>
                  <tr>
                    <th>Proměnná</th>
                    <th>Popis</th>
                    <th>Směr</th>
                  </tr>
                </thead>
                <tbody>
                  {PREDICTORS.map(({ code, label, dir, positive }) => (
                    <tr key={code}>
                      <td>
                        <code style={{ fontFamily: 'Space Grotesk, sans-serif', fontSize: '0.8rem', color: 'var(--gold)' }}>
                          {code}
                        </code>
                      </td>
                      <td className="td-dim">{label}</td>
                      <td className={positive ? 'td-pos' : 'td-neg'}>{dir} {positive ? 'pozitivní' : 'negativní'}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>

        <div className="formula reveal delay-2">
          <strong>Model OLS:</strong>
          <br />
          pirati_pct ~ VZDELANI_VYSOKO + VZDELANI_STR_BEZ + NEPRAC_DUCH
          <br />
          &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
          + PODNIKATELE + NEZAMEST + VERICI
        </div>
      </div>
    </section>
  )
}
