/* jshint esversion: 6 */

export default {
  mounted() {
    const dqElt = this.el.querySelector('#declare-dq-btn');
    const dqPlayerElts = this.el.querySelectorAll('.dqplayer');

    dqElt.addEventListener('click', function(){
      dqElt.classList.add('hidden');
      dqPlayerElts.forEach((dqPlayerElt) => {
        dqPlayerElt.classList.remove('hidden');
      });
    });
  }
};
