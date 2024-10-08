/* jshint esversion: 6 */

import ConfettiGenerator from './confetti-generator.min';

export default {
  mounted() {
    this.el.width  = window.innerWidth;
    this.el.height = window.innerHeight;
    let confettiOptions;

    if (this.el.dataset.dq == "true") {
      confettiOptions = {
        "target": this.el,
        "max": "70",
        "size": "1",
        "animate": true,
        "props": [
          {
            "type":"svg",
            "src":"/images/confetti/woman-no.png",
            "size": 50,
            "weight": 0.1
          },
          {
            "type":"svg",
            "src":"/images/confetti/woman-no.png",
            "size": 30,
            "weight": 0.5
          },
          {
            "type":"svg",
            "src":"/images/confetti/woman-no.png",
            "size": 20,
            "weight": 0.4
          }
        ],
        "colors": [],
        "clock": "30",
        "rotate": false,
        "start_from_edge": true,
        "respawn": false
      };
    } else {
      confettiOptions = {
        "target": this.el,
        "max": "140",
        "size": "1",
        "animate": true,
        "props": [
          "circle",
          "square",
          "triangle",
          "line",
          {
            "type":"svg",
            "src":"/images/confetti/c1.svg",
            "size": 30,
            "weight": 0.06
          },
          {
            "type":"svg",
            "src":"/images/confetti/df.svg",
            "size": 30,
            "weight": 0.06
          },
          {
            "type":"svg",
            "src":"/images/confetti/dz.svg",
            "size": 30,
            "weight": 0.06
          }
        ],
        "colors": [
          [165, 104, 246],
          [230, 61, 135],
          [0, 199, 228],
          [253, 214, 126]
        ],
        "clock": "30",
        "rotate": false,
        "start_from_edge": true,
        "respawn": this.el.dataset.winner == "true"
      };
    }
    (new ConfettiGenerator(confettiOptions)).render();
  },
  updated() {
    // if this doesn't get resized here, the canvas gets stretched on all
    // liveview updates. I think it's because canvas is weird and you can't use
    // CSS like other elements.
    this.el.width  = window.innerWidth;
    this.el.height = window.innerHeight;
  }
};
