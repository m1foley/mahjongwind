/* jshint esversion: 6 */

import Sortable from 'sortablejs';

export default {
  mounted() {
    const hook = this;
    const dropzone = this.el;

    switch(dropzone.id) {
      case 'discards':
        Sortable.create(dropzone, {
          group: {
            name: 'discards',
            put: function (to, from) {
              if (dropzone.classList.contains('current-user-discarding')) {
                return ['concealed-0', 'exposed-0', 'peektile-0'];
              } else {
                return false;
              }
            },
            pull: function (to, from) {
              if (dropzone.classList.contains('enable-pull-from-discards')) {
                return ['exposed-0', 'wintile-0'];
              } else {
                return false;
              }
            }
          },
          sort: false,
          direction: 'horizontal',
          // This mess is to optimize LiveView dirty detection: dynamically
          // setting a class on the draggable tile makes LiveView mark the
          // discards as dirty even if an action didn't involve the discards.
          // This causes too much information to be sent over the wire.
          // These rules are a hardcoded version of the ones declared in CSS.
          draggable: '.dglow-b1-0 #b1-0,.dglow-b1-1 #b1-1,.dglow-b1-2 #b1-2,.dglow-b1-3 #b1-3,.dglow-b2-0 #b2-0,.dglow-b2-1 #b2-1,.dglow-b2-2 #b2-2,.dglow-b2-3 #b2-3,.dglow-b3-0 #b3-0,.dglow-b3-1 #b3-1,.dglow-b3-2 #b3-2,.dglow-b3-3 #b3-3,.dglow-b4-0 #b4-0,.dglow-b4-1 #b4-1,.dglow-b4-2 #b4-2,.dglow-b4-3 #b4-3,.dglow-b5-0 #b5-0,.dglow-b5-1 #b5-1,.dglow-b5-2 #b5-2,.dglow-b5-3 #b5-3,.dglow-b6-0 #b6-0,.dglow-b6-1 #b6-1,.dglow-b6-2 #b6-2,.dglow-b6-3 #b6-3,.dglow-b7-0 #b7-0,.dglow-b7-1 #b7-1,.dglow-b7-2 #b7-2,.dglow-b7-3 #b7-3,.dglow-b8-0 #b8-0,.dglow-b8-1 #b8-1,.dglow-b8-2 #b8-2,.dglow-b8-3 #b8-3,.dglow-b9-0 #b9-0,.dglow-b9-1 #b9-1,.dglow-b9-2 #b9-2,.dglow-b9-3 #b9-3,.dglow-c1-0 #c1-0,.dglow-c1-1 #c1-1,.dglow-c1-2 #c1-2,.dglow-c1-3 #c1-3,.dglow-c2-0 #c2-0,.dglow-c2-1 #c2-1,.dglow-c2-2 #c2-2,.dglow-c2-3 #c2-3,.dglow-c3-0 #c3-0,.dglow-c3-1 #c3-1,.dglow-c3-2 #c3-2,.dglow-c3-3 #c3-3,.dglow-c4-0 #c4-0,.dglow-c4-1 #c4-1,.dglow-c4-2 #c4-2,.dglow-c4-3 #c4-3,.dglow-c5-0 #c5-0,.dglow-c5-1 #c5-1,.dglow-c5-2 #c5-2,.dglow-c5-3 #c5-3,.dglow-c6-0 #c6-0,.dglow-c6-1 #c6-1,.dglow-c6-2 #c6-2,.dglow-c6-3 #c6-3,.dglow-c7-0 #c7-0,.dglow-c7-1 #c7-1,.dglow-c7-2 #c7-2,.dglow-c7-3 #c7-3,.dglow-c8-0 #c8-0,.dglow-c8-1 #c8-1,.dglow-c8-2 #c8-2,.dglow-c8-3 #c8-3,.dglow-c9-0 #c9-0,.dglow-c9-1 #c9-1,.dglow-c9-2 #c9-2,.dglow-c9-3 #c9-3,.dglow-n1-0 #n1-0,.dglow-n1-1 #n1-1,.dglow-n1-2 #n1-2,.dglow-n1-3 #n1-3,.dglow-n2-0 #n2-0,.dglow-n2-1 #n2-1,.dglow-n2-2 #n2-2,.dglow-n2-3 #n2-3,.dglow-n3-0 #n3-0,.dglow-n3-1 #n3-1,.dglow-n3-2 #n3-2,.dglow-n3-3 #n3-3,.dglow-n4-0 #n4-0,.dglow-n4-1 #n4-1,.dglow-n4-2 #n4-2,.dglow-n4-3 #n4-3,.dglow-n5-0 #n5-0,.dglow-n5-1 #n5-1,.dglow-n5-2 #n5-2,.dglow-n5-3 #n5-3,.dglow-n6-0 #n6-0,.dglow-n6-1 #n6-1,.dglow-n6-2 #n6-2,.dglow-n6-3 #n6-3,.dglow-n7-0 #n7-0,.dglow-n7-1 #n7-1,.dglow-n7-2 #n7-2,.dglow-n7-3 #n7-3,.dglow-n8-0 #n8-0,.dglow-n8-1 #n8-1,.dglow-n8-2 #n8-2,.dglow-n8-3 #n8-3,.dglow-n9-0 #n9-0,.dglow-n9-1 #n9-1,.dglow-n9-2 #n9-2,.dglow-n9-3 #n9-3,.dglow-df-0 #df-0,.dglow-df-1 #df-1,.dglow-df-2 #df-2,.dglow-df-3 #df-3,.dglow-dp-0 #dp-0,.dglow-dp-1 #dp-1,.dglow-dp-2 #dp-2,.dglow-dp-3 #dp-3,.dglow-dz-0 #dz-0,.dglow-dz-1 #dz-1,.dglow-dz-2 #dz-2,.dglow-dz-3 #dz-3,.dglow-we-0 #we-0,.dglow-we-1 #we-1,.dglow-we-2 #we-2,.dglow-we-3 #we-3,.dglow-ws-0 #ws-0,.dglow-ws-1 #ws-1,.dglow-ws-2 #ws-2,.dglow-ws-3 #ws-3,.dglow-ww-0 #ww-0,.dglow-ww-1 #ww-1,.dglow-ww-2 #ww-2,.dglow-ww-3 #ww-3,.dglow-wn-0 #wn-0,.dglow-wn-1 #wn-1,.dglow-wn-2 #wn-2,.dglow-wn-3 #wn-3',
          ghostClass: 'sortable-ghost',
          swapThreshold: 1,
          animation: 0,
          emptyInsertThreshold: 0,
          delay: 50,
          delayOnTouchOnly: true,
          onStart: function (evt) {
            const hlSelector = '#wintile-0';
            document.querySelectorAll(hlSelector).forEach((hlZone) => {
              hlZone.classList.add('with-description');
            });
          },
          onEnd: function (evt) {
            document.querySelectorAll('.dropzone.with-description').forEach((hlZone) => {
              hlZone.classList.remove('with-description');
            });
          },
        });
        break;
      case 'concealed-0':
        Sortable.create(dropzone, {
          group: {
            name: 'concealed-0',
            put: function (to, from) {
              let ids = ['exposed-0', 'hiddengongs-0', 'correctiontiles', 'peektile-0'];
              if (dropzone.classList.contains('enable-pull-from-discards')) {
                ids.push('discards');
              }
              return ids;
            },
            pull: function (to, from) {
              let ids = ['exposed-0', 'hiddengongs-0', 'wintile-0'];
              if (dropzone.classList.contains('current-user-discarding')) {
                ids.push('discards');
              }
              return ids;
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
            // if the action involves adding/removing from the player's hand,
            // we'll need to know what the updated list(s) look like
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
            hook.pushEvent('dropped', {
              draggedFromId: evt.from.id,
              draggedToId: evt.to.id,
              draggedFromList: draggedFromList,
              draggedToList: draggedToList,
              draggedId: draggedId
            });
            // The correction tile gets replaced on the backend and when the
            // HTML gets updated, but it still persists in the DOM unless we
            // remove it manually like this
            if (draggedId == 'decktile') {
              evt.item.remove();
            }
          }
        });
        break;
      case 'exposed-0':
        Sortable.create(dropzone, {
          group: {
            name: 'exposed-0',
            put: ['concealed-0', 'hiddengongs-0', 'discards'],
            pull: ['concealed-0', 'hiddengongs-0', 'discards', 'wintile-0']
          },
          direction: 'horizontal',
          draggable: '.draggable',
          ghostClass: 'sortable-ghost',
          swapThreshold: 0.2,
          animation: 100,
          emptyInsertThreshold: 0,
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

            hook.pushEvent('dropped', {
              draggedFromId: evt.from.id,
              draggedToId: evt.to.id,
              draggedFromList: draggedFromList,
              draggedToList: draggedToList,
              draggedId: evt.item.id
            });
          }
        });
        break;
      case 'hiddengongs-0':
        Sortable.create(dropzone, {
          group: {
            name: 'hiddengongs-0',
            put: ['concealed-0', 'exposed-0', 'peektile-0'],
            pull: ['concealed-0', 'exposed-0'] // for accidents
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
            // Interactions with concealed, exposed, and peektile are handled
            // in their respective onSort hooks. That should leave just
            // sorting.
            if (['concealed-0', 'exposed-0', 'peektile-0'].includes(evt.from.id) ||
              ['concealed-0', 'exposed-0', 'peektile-0'].includes(evt.to.id)) {
              return;
            }

            let draggedToList = [];
            const draggedToNodes = evt.to.querySelectorAll('.draggable');
            for (let i = 0; i < draggedToNodes.length; i++) {
              draggedToList.push(draggedToNodes[i].id);
            }

            hook.pushEvent('dropped', {
              draggedFromId: evt.from.id,
              draggedToId: evt.to.id,
              draggedToList: draggedToList,
              draggedId: evt.item.id
            });
          }
        });
        break;
      case 'peektile-0':
        Sortable.create(dropzone, {
          group: {
            name: 'peektile-0',
            put: false,
            pull: ['discards', 'concealed-0', 'hiddengongs-0', 'wintile-0']
          },
          sort: false,
          direction: 'horizontal',
          draggable: '.draggable',
          ghostClass: 'sortable-ghost',
          animation: 0,
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
            // Interactions with concealed and exposed are handled in their
            // respective onSort hooks. That should leave discards, hidden
            // gongs, and the win tile.
            if (['concealed-0', 'exposed-0'].includes(evt.to.id)) {
              return;
            }

            let draggedToList = [];
            const draggedToNodes = evt.to.querySelectorAll('.draggable');
            for (let i = 0; i < draggedToNodes.length; i++) {
              draggedToList.push(draggedToNodes[i].id);
            }

            const draggedId = evt.item.id;
            hook.pushEvent('dropped', {
              draggedFromId: evt.from.id,
              draggedToId: evt.to.id,
              draggedToList: draggedToList,
              draggedId: draggedId
            });
          }
        });
        break;
      case 'correctiontiles':
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
          emptyInsertThreshold: 0,
          delay: 50,
          delayOnTouchOnly: true
        });
        break;
      case 'wintile-0':
        Sortable.create(dropzone, {
          group: {
            name: 'wintile-0',
            put: ['discards', 'concealed-0', 'exposed-0', 'peektile-0'],
            pull: false // can only undo via Undo button
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
            // Interactions with concealed, exposed, and peektiles are handled
            // in their respective onSort hooks. That should leave just
            // discards.
            if (['concealed-0', 'exposed-0', 'peektile-0'].includes(evt.from.id)) {
              return;
            }

            hook.pushEvent('dropped', {
              draggedFromId: evt.from.id,
              draggedToId: evt.to.id,
              draggedId: evt.item.id
            });
          }
        });
        break;
    }
  }
};
