import { useReveal } from '../hooks/useReveal'

export default function OStrane() {
  const ref = useReveal()

  return (
    <section id="o-strane" ref={ref}>
      <div className="container">
        <div className="section-label">01 — O straně</div>
        <h2 className="section-title reveal">
          Česká <span className="gold">pirátská</span> strana
        </h2>
        <p className="section-lead reveal delay-1">
          Strana digitální éry — transparentnost, participace a otevřená správa věcí veřejných.
        </p>

        <div className="two-col">
          <div>
            <div className="gold-line reveal" />
            <p className="reveal delay-1">
              Česká pirátská strana byla{' '}
              <strong>založena v roce 2009</strong>,
              jako součást mezinárodního pirátského hnutí.
              Hlásí se k ideálům digitální svobody, radikální transparentnosti
              a přímé demokracie.
            </p>
            <p className="reveal delay-2" style={{ marginTop: '1rem' }}>
              Cílová voličská základna je tvořena zejména{' '}
              <strong>mladými, vysokoškolsky vzdělanými voliči v metropolitních oblastech</strong>{' '}
              — Praha, Brno a větší univerzitní centra. Tento vzorec je empiricky
              potvrzen i naší prostorovou analýzou.
            </p>
            <ul className="check-list">
              <li className="reveal delay-2">Digitální bezpečnost a ochrana soukromí</li>
              <li className="reveal delay-3">Transparentnost veřejné správy a protikorupce</li>
              <li className="reveal delay-3">Regulace technologií a otevřená data</li>
              <li className="reveal delay-4">Kritika centralismu a zákaz lobování</li>
              <li className="reveal delay-4">Občanská participace na rozhodování</li>
            </ul>
          </div>

          <div className="reveal delay-2">
            <div
              className="card"
              style={{ textAlign: 'center', padding: '2.5rem 2rem' }}
            >
              <img
                src={`${import.meta.env.BASE_URL}logo_pirati.png`}
                alt="Česká pirátská strana"
                style={{ maxWidth: 260, width: '100%', margin: '0 auto', display: 'block' }}
              />
              <div style={{ marginTop: '1.5rem', display: 'flex', gap: '0.5rem', justifyContent: 'center', flexWrap: 'wrap' }}>
                <span className="badge">Pirátské hnutí</span>
                <span className="badge">od 2009</span>
                <span className="badge">Mezinárodní</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}
