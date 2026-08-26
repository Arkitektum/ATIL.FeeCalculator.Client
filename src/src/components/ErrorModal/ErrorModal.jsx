import { useEffect, useRef } from 'react';

function ErrorModal({ message, onClose }) {
   const dialogRef = useRef(null);
   const isOpen = message !== null;

   useEffect(
      () => {
         const dialog = dialogRef.current;

         if (isOpen && !dialog.open) {
            dialog.showModal();
         } else if (!isOpen && dialog.open) {
            dialog.close();
         }
      },
      [isOpen]
   );

   return (
      <dialog className="error-modal" ref={dialogRef} onCancel={onClose} onClose={onClose}>
         <div className="error-modal__header">
            <span>En feil har oppstått</span>
            <span className="error-modal__close" role="button" aria-label="Lukk" onClick={onClose}></span>
         </div>

         <div className="error-modal__content">
            <p>{message}</p>
         </div>

         <div className="error-modal__footer">
            <button onClick={onClose}>Lukk</button>
         </div>
      </dialog>
   );
}

export default ErrorModal;
