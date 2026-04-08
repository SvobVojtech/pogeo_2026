import { useEffect } from 'react'

export default function Lightbox({ src, alt, onClose }) {
  useEffect(() => {
    const handler = (e) => { if (e.key === 'Escape') onClose() }
    window.addEventListener('keydown', handler)
    return () => window.removeEventListener('keydown', handler)
  }, [onClose])

  return (
    <div className="lightbox-overlay" onClick={onClose}>
      <button className="lightbox-close" onClick={onClose} aria-label="Zavřít">✕</button>
      <img src={src} alt={alt} onClick={(e) => e.stopPropagation()} />
    </div>
  )
}
