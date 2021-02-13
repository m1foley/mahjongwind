/* jshint esversion: 6 */

export default {
  mounted() {
    const copyElt = document.getElementById('copy-to-clipboard');
    copyElt.addEventListener('click', copyToClipboard, false);

    function copyToClipboard() {
      const element = document.getElementById('game-url');
      element.select();
      element.setSelectionRange(0, 99999);
      document.execCommand("copy");
      element.blur();
      document.getElementById("clipboard-success").classList.remove("hidden");
    }
  }
};
