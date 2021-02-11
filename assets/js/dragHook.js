/* jshint esversion: 6 */

import Sortable from 'sortablejs';

export default {
  mounted() {
    const hook = this;
    const selector = '#' + this.el.id;

    document.querySelectorAll('#discards.dropzone.dzuninitialized').forEach((dropzone) => {
      Sortable.create(dropzone, {
        group: {
          name: 'discards',
          put: function (to, from) {
            if (dropzone.classList.contains('current-user-discarding')) {
              return ['concealed-0'];
            } else {
              return false;
            }
          },
          pull: function (to, from) {
            if (dropzone.classList.contains('enable-pull-from-discards')) {
              return ['exposed-0'];
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
      dropzone.classList.remove('dzuninitialized');
    });

    document.querySelectorAll('#concealed-0.dropzone.dzuninitialized').forEach((dropzone) => {
      Sortable.create(dropzone, {
        group: {
          name: 'concealed-0',
          put: function (to, from) {
            if (dropzone.classList.contains('enable-pull-from-discards')) {
              return ['discards', 'exposed-0', 'hiddengongs-0', 'correctiontiles', 'deckoffer'];
            } else {
              return ['exposed-0', 'hiddengongs-0', 'correctiontiles'];
            }
          },
          pull: function (to, from) {
            if (dropzone.classList.contains('current-user-discarding')) {
              return ['discards', 'exposed-0', 'hiddengongs-0', 'wintile-0'];
            } else {
              return ['exposed-0', 'hiddengongs-0', 'wintile-0'];
            }
          },
        },
        direction: 'horizontal',
        draggable: '.draggable',
        ghostClass: 'sortable-ghost',
        swapThreshold: 0.2,
        animation: 100,
        delay: 50,
        delayOnTouchOnly: true,
        onStart: function (evt) {
          const hlSelector = '#hiddengongs-0, #wintile-0';
          document.querySelectorAll(hlSelector).forEach((hlZone) => {
            hlZone.classList.add('with-description');
          });
        },
        onEnd: function (evt) {
          document.querySelectorAll('.dropzone.with-description').forEach((hlZone) => {
            hlZone.classList.remove('with-description');
          });
        },
        onSort: function (evt) {
          // if the action involves adding/removing from the player's personal
          // tiles, we'll need to know what the updated list(s) look like
          let draggedToList = [];
          if (['concealed-0', 'exposed-0', 'hiddengongs-0'].includes(evt.to.id)) {
            const draggedToNodes = evt.to.querySelectorAll('.draggable');
            for (let i = 0; i < draggedToNodes.length; i++) {
              draggedToList.push(draggedToNodes[i].id);
            }
          }
          let draggedFromList = [];
          if (['concealed-0', 'exposed-0', 'hiddengongs-0'].includes(evt.from.id)) {
            const draggedFromNodes = evt.from.querySelectorAll('.draggable');
            for (let i = 0; i < draggedFromNodes.length; i++) {
              draggedFromList.push(draggedFromNodes[i].id);
            }
          }

          const draggedId = evt.item.id;
          // The deck tile gets replaced on the backend, but not in the DOM
          // unless we do it manually like this
          if (draggedId == 'decktile') {
            evt.item.remove();
          }

          hook.pushEventTo(selector, 'dropped', {
            draggedFromId: evt.from.id,
            draggedToId: evt.to.id,
            draggedFromList: draggedFromList,
            draggedToList: draggedToList,
            draggedId: draggedId
          });
        }
      });
      dropzone.classList.remove('dzuninitialized');
    });

    document.querySelectorAll('#exposed-0.dropzone.dzuninitialized').forEach((dropzone) => {
      Sortable.create(dropzone, {
        group: {
          name: 'exposed-0',
          put: ['concealed-0', 'hiddengongs-0', 'discards'],
          pull: ['concealed-0', 'hiddengongs-0', 'wintile-0']
        },
        direction: 'horizontal',
        draggable: '.draggable',
        ghostClass: 'sortable-ghost',
        swapThreshold: 0.2,
        animation: 100,
        delay: 50,
        delayOnTouchOnly: true,
        onStart: function (evt) {
          const hlSelector = '#hiddengongs-0, #wintile-0';
          document.querySelectorAll(hlSelector).forEach((hlZone) => {
            hlZone.classList.add('with-description');
          });
        },
        onEnd: function (evt) {
          document.querySelectorAll('.dropzone.with-description').forEach((hlZone) => {
            hlZone.classList.remove('with-description');
          });
        },
        onSort: function (evt) {
          // Any interaction with the concealed tiles are handled in the
          // concealed-0 onSort
          if (evt.to.id == 'concealed-0' || evt.from.id == 'concealed-0') {
            return;
          }

          let draggedToList = [];
          const draggedToNodes = evt.to.querySelectorAll('.draggable');
          for (let i = 0; i < draggedToNodes.length; i++) {
            draggedToList.push(draggedToNodes[i].id);
          }
          let draggedFromList = [];
          if (evt.to.id != 'exposed-0' || evt.from.id != 'exposed-0') {
            const draggedFromNodes = evt.from.querySelectorAll('.draggable');
            for (let i = 0; i < draggedFromNodes.length; i++) {
              draggedFromList.push(draggedFromNodes[i].id);
            }
          }

          hook.pushEventTo(selector, 'dropped', {
            draggedFromId: evt.from.id,
            draggedToId: evt.to.id,
            draggedFromList: draggedFromList,
            draggedToList: draggedToList,
            draggedId: evt.item.id
          });
        }
      });
      dropzone.classList.remove('dzuninitialized');
    });

    document.querySelectorAll('#hiddengongs-0.dropzone.dzuninitialized').forEach((dropzone) => {
      Sortable.create(dropzone, {
        group: {
          name: 'hiddengongs-0',
          put: ['concealed-0', 'exposed-0'],
          pull: ['concealed-0', 'exposed-0'] // for accidents
        },
        direction: 'horizontal',
        draggable: '.draggable',
        ghostClass: 'sortable-ghost',
        swapThreshold: 0.2,
        animation: 100,
        delay: 50,
        delayOnTouchOnly: true,
        onSort: function (evt) {
          // Any interactions with the concealed or exposed tiles are handled in
          // their respective onSort methods. That leaves just sorting.
          if (evt.to.id != 'hiddengongs-0' || evt.from.id != 'hiddengongs-0') {
            return;
          }

          let draggedToList = [];
          const draggedToNodes = evt.to.querySelectorAll('.draggable');
          for (let i = 0; i < draggedToNodes.length; i++) {
            draggedToList.push(draggedToNodes[i].id);
          }

          hook.pushEventTo(selector, 'dropped', {
            draggedFromId: evt.from.id,
            draggedToId: evt.to.id,
            draggedToList: draggedToList,
            draggedId: evt.item.id
          });
        }
      });
      dropzone.classList.remove('dzuninitialized');
    });

    document.querySelectorAll('#deckoffer.dropzone.dzuninitialized').forEach((dropzone) => {
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
      dropzone.classList.remove('dzuninitialized');
    });

    document.querySelectorAll('#correctiontiles.dropzone.dzuninitialized').forEach((dropzone) => {
      Sortable.create(dropzone, {
        group: {
          name: 'correctiontiles',
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
      dropzone.classList.remove('dzuninitialized');
    });
  }
};
