/* jshint esversion: 6 */

export default {
  mounted() {
    const clipboardElt = this.el.querySelector('.copy-to-clipboard');
    const gameUrlElt = this.el.querySelector('.game-url');

    clipboardElt.addEventListener('click', function(){
      gameUrlElt.select();
      gameUrlElt.setSelectionRange(0, 99999);
      document.execCommand("copy");
      gameUrlElt.blur();
      clipboardElt.textContent = "✅";
      new Promise((resolve) => setTimeout(resolve, 2000)).then(() => {
        clipboardElt.textContent = "📋";
      });
    });
  }
};
