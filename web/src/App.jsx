import Nav from './components/Nav'
import Hero from './components/Hero'
import OStrane from './components/OStrane'
import Historie from './components/Historie'
import ProstorovaRozdily from './components/ProstorovaRozdily'
import DataMetodika from './components/DataMetodika'
import OLSModel from './components/OLSModel'
import MoransI from './components/MoransI'
import GWRModel from './components/GWRModel'
import LokKoeficienty from './components/LokKoeficienty'
import LokR2 from './components/LokR2'
import Shrnuti from './components/Shrnuti'
import Footer from './components/Footer'

export default function App() {
  return (
    <>
      <Nav />
      <main>
        <Hero />
        <OStrane />
        <Historie />
        <ProstorovaRozdily />
        <DataMetodika />
        <OLSModel />
        <MoransI />
        <GWRModel />
        <LokKoeficienty />
        <LokR2 />
        <Shrnuti />
      </main>
      <Footer />
    </>
  )
}
