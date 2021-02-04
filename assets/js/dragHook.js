/* jshint esversion: 6 */

import Sortable from 'sortablejs';

export default {
  mounted() {
    let dragged;
    const hook = this;
    const selector = '#' + this.el.id;

    document.querySelectorAll('.dropzone').forEach((dropzone) => {
      new Sortable(dropzone, {
        direction: 'horizontal',
        group: 'shared',
        draggable: '.draggable',
        ghostClass: 'sortable-ghost',
        swapThreshold: 0.2,
        animation: 100,
        emptyInsertThreshold: 0,
        delay: 50,
        delayOnTouchOnly: true,
        onMove: function (evt, originalEvent) {
          if (evt.to.classList.contains('nodrops')) {
            return false;
          }
          // ignore inadvertent drags
          if (evt.from.id == 'discards' && evt.to.id == 'discards') {
            return false;
          }
        },
        onEnd: function (evt) {
          if (evt.to.classList.contains('nodrops')) {
            return false;
          }
          // ignore inadvertent drags
          if (evt.from.id == 'discards' && evt.to.id == 'discards') {
            return false;
          }

          let draggedToList = [];
          // discards are sorted in the backend so we don't need to know what it is
          if (evt.to.id != 'discards') {
            const draggedToNodes = evt.to.querySelectorAll('.draggable');
            for (let i = 0; i < draggedToNodes.length; i++) {
              draggedToList.push(draggedToNodes[i].id);
            }
          }

          hook.pushEventTo(selector, 'dropped', {
            draggedFromId: evt.from.id,
            draggedToId: evt.to.id,
            draggedToList: draggedToList,
            draggedId: evt.item.id
          });
        },
      });
    });
  },
};
