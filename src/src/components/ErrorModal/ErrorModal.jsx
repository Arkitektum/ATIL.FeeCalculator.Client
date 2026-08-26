import PureModal from 'react-pure-modal';

function ErrorModal({ message, onClose }) {
   return (
      <PureModal
         header={
            <span className="custom-panel-heading">
               <span>En feil har oppstått</span>
               <span className="close-button" role="button" onClick={onClose}></span>
            </span>
         }
         footer={
            <div>
               <button onClick={onClose}>Lukk</button>
            </div>
         }
         isOpen={message !== null}
      >
         <p>{message}</p>
      </PureModal>
   );
}

export default ErrorModal;