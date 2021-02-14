/* jshint esversion: 6 */

export default {
  mounted() {
    document.querySelectorAll('.copy-to-clipboard').forEach((copyElt) => {
      copyElt.addEventListener('click', copyToClipboard, false);
      function copyToClipboard() {
        const element = document.getElementById('game-url');
        element.select();
        element.setSelectionRange(0, 99999);
        document.execCommand("copy");
        element.blur();
        copyElt.textContent = "✅";
        new Promise((resolve) => setTimeout(resolve, 2000)).then(() => {
          copyElt.textContent = "📋";
        });
      }
    });
  }
};
