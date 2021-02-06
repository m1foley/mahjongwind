/* jshint esversion: 6 */

import Sortable from 'sortablejs';

export default {
  mounted() {
    const hook = this;
    const selector = '#' + this.el.id;

    document.querySelectorAll('#discards.dropzone').forEach((dropzone) => {
      Sortable.create(dropzone, {
        group: {
          name: 'discards',
          put: function (to, from) {
            if (dropzone.classList.contains('enableputs')) {
              return ['concealed-0'];
            } else {
              return false;
            }
          },
          pull: function (to, from) {
            if (dropzone.classList.contains('enablepulls')) {
              return ['concealed-0'];
            } else {
              return false;
            }
          }
        },
        sort: false,
        direction: 'horizontal',
        draggable: '.draggable',
        ghostClass: 'sortable-ghost',
        swapThreshold: 1,
        animation: 0,
        emptyInsertThreshold: 0,
        delay: 50,
        delayOnTouchOnly: true
      });
    });

    document.querySelectorAll('#concealed-0.dropzone').forEach((dropzone) => {
      Sortable.create(dropzone, {
        group: {
          name: 'concealed-0',
          put: function (to, from) {
            if (dropzone.classList.contains('enableputs')) {
              return ['concealed-0', 'discards', 'deckoffer'];
            } else {
              return false;
            }
          },
          pull: function (to, from) {
            if (dropzone.classList.contains('enablepulls')) {
              return ['discards'];
            } else {
              return false;
            }
          },
        },
        direction: 'horizontal',
        draggable: '.draggable',
        ghostClass: 'sortable-ghost',
        swapThreshold: 0.2,
        animation: 100,
        emptyInsertThreshold: 0,
        delay: 50,
        delayOnTouchOnly: true,
        onSort: function (evt) {
          let draggedToList = [];
          // we only need to know the new contents if dragging to concealed-0
          if (evt.to.id == 'concealed-0') {
            const draggedToNodes = evt.to.querySelectorAll('.draggable');
            for (let i = 0; i < draggedToNodes.length; i++) {
              draggedToList.push(draggedToNodes[i].id);
            }
          }

          const draggedId = evt.item.id;
          // The deck tile gets removed on the backend, but not in the DOM
          // unless we do it manually like this
          if (draggedId == "decktile") {
            evt.item.remove();
          }

          hook.pushEventTo(selector, 'dropped', {
            draggedFromId: evt.from.id,
            draggedToId: evt.to.id,
            draggedToList: draggedToList,
            draggedId: draggedId
          });
        }
      });
    });

    document.querySelectorAll('#deckoffer.dropzone').forEach((dropzone) => {
      Sortable.create(dropzone, {
        group: {
          name: 'deckoffer',
          put: false,
          pull: 'clone'
        },
        sort: false,
        direction: 'horizontal',
        draggable: '.draggable',
        ghostClass: 'sortable-ghost',
        animation: 0,
        delay: 50,
        delayOnTouchOnly: true
      });
    });

  }
};
