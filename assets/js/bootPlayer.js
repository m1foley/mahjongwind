/* jshint esversion: 6 */

export default {
  mounted() {
    const bootElt = this.el.querySelector('#boot-player-btn');
    const bootPlayerElts = this.el.querySelectorAll('.bootplayer');

    bootElt.addEventListener('click', function(){
      bootElt.classList.add('hidden');
      bootPlayerElts.forEach((bootPlayerElt) => {
        bootPlayerElt.classList.remove('hidden');
      });
    });
  }
};
