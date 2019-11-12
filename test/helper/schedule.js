const Web3Utils = require('web3-utils');


function getEpochOffsetForEventType (eventType) {
  if (eventType === 5) { return 20; } // IED
  if (eventType === 15) { return 25; } // PR
  if (eventType === 8) { return 30; } // IP
  if (eventType === 7) { return 40; } // IPCI
  if (eventType === 4) { return 50; } // FP
  if (eventType === 2) { return 60; } // DV
  if (eventType === 9) { return 80; } // MR
  if (eventType === 17) { return 90; } // RRF
  if (eventType === 18) { return 100; } // RR
  if (eventType === 19) { return 110; } // SC
  if (eventType === 6) { return 120; } // IPCB
  if (eventType === 16) { return 130; } // PRD
  if (eventType === 21) { return 140; } // TD
  if (eventType === 20) { return 150; } // STD
  if (eventType === 10) { return 160; } // MD
  if (eventType === 0) { return 950; } // AD
  return 0;
}

function sortProtoEvents (protoEvents) {
  protoEvents.sort((protoEventA, protoEventB) => {
    const { eventType: eventTypeA, scheduleTime: scheduleTimeA } = decodeProtoEvent(protoEventA);
    const { eventType: eventTypeB, scheduleTime: scheduleTimeB } = decodeProtoEvent(protoEventB)

    if (scheduleTimeA == 0) { return 1 }
    if (scheduleTimeB == 0) { return -1 }
    if (scheduleTimeA > scheduleTimeB) { return 1 }
    if (scheduleTimeA < scheduleTimeB) { return -1 }
    
    if (getEpochOffsetForEventType(eventTypeA) > getEpochOffsetForEventType(eventTypeB)) { 
      return 1; 
    }
    if (getEpochOffsetForEventType(eventTypeA) < getEpochOffsetForEventType(eventTypeB)) {
      return -1;
    }

    return 0
  });

  return protoEvents;
}

function removeNullProtoEvents (protoEventSchedule) {
  const compactProtoEventSchedule = [];

  for (protoEvent of protoEventSchedule) {
    if (decodeProtoEvent(protoEvent).scheduleTime === 0) { continue }
    compactProtoEventSchedule.push(protoEvent);
  }

  return compactProtoEventSchedule;
}

function decodeProtoEvent (encodedProtoEvent) {
  return {
    eventType: Web3Utils.hexToNumber('0x' + String(encodedProtoEvent).substr(2, 2)),
    scheduleTime: Web3Utils.hexToNumber('0x' + String(encodedProtoEvent).substr(10, encodedProtoEvent.length))
  };
}

function parseProtoEventSchedule (encodedProtoEventSchedule) {
  return removeNullProtoEvents(
    encodedProtoEventSchedule
  ).map((encodedProtoEvent) => decodeProtoEvent(encodedProtoEvent));
}

module.exports = { 
  sortProtoEvents, 
  removeNullProtoEvents, 
  decodeProtoEvent,
  parseProtoEventSchedule
}
