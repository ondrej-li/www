/* clip.html - copy buttons and the scratch pad.
   No dependencies, no storage beyond this browser's localStorage. */
(function () {
  'use strict';

  var KEY = 'ondralinek-clip';
  var textarea = document.getElementById('scratch');
  var status = document.getElementById('status');

  function say(message) {
    if (!status) return;
    status.textContent = message;
  }

  /* ---------------------------------------------------------- clipboard */
  function fallbackCopy(text) {
    var helper = document.createElement('textarea');
    helper.value = text;
    helper.setAttribute('readonly', '');
    helper.style.position = 'fixed';
    helper.style.top = '-1000px';
    document.body.appendChild(helper);
    helper.select();
    var ok = false;
    try {
      ok = document.execCommand('copy');
    } catch (error) {
      ok = false;
    }
    document.body.removeChild(helper);
    return ok;
  }

  function copy(text, onDone) {
    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(text).then(onDone, function () {
        if (fallbackCopy(text)) onDone();
      });
      return;
    }
    if (fallbackCopy(text)) onDone();
  }

  /* A copy button per code block, added here so the HTML stays readable and a
     browser without JavaScript simply gets the commands and no button. */
  var blocks = document.querySelectorAll('pre');
  Array.prototype.forEach.call(blocks, function (pre) {
    var wrapper = document.createElement('div');
    wrapper.className = 'code';
    pre.parentNode.insertBefore(wrapper, pre);
    wrapper.appendChild(pre);

    var button = document.createElement('button');
    button.type = 'button';
    button.className = 'copy';
    button.textContent = 'copy';
    wrapper.appendChild(button);

    button.addEventListener('click', function () {
      copy(pre.innerText.replace(/\n$/, ''), function () {
        button.textContent = 'copied';
        button.className = 'copy is-done';
        window.setTimeout(function () {
          button.textContent = 'copy';
          button.className = 'copy';
        }, 1400);
      });
    });
  });

  /* ---------------------------------------------------------- scratch pad */
  if (!textarea) return;

  function read() {
    try {
      return window.localStorage.getItem(KEY) || '';
    } catch (error) {
      return '';
    }
  }

  function write(value) {
    try {
      window.localStorage.setItem(KEY, value);
      return true;
    } catch (error) {
      return false;
    }
  }

  var saved = read();
  if (saved) {
    textarea.value = saved;
    say('restored ' + saved.length + ' characters from this browser');
  } else {
    say('nothing saved yet - it stays in this browser, on this device');
  }

  var pending = null;
  textarea.addEventListener('input', function () {
    say('unsaved…');
    window.clearTimeout(pending);
    pending = window.setTimeout(function () {
      say(write(textarea.value) ? 'saved locally' : 'could not save (storage blocked or full)');
    }, 400);
  });

  document.getElementById('copy-scratch').addEventListener('click', function () {
    copy(textarea.value, function () { say('scratch pad copied to the clipboard'); });
  });

  document.getElementById('clear-scratch').addEventListener('click', function () {
    if (!textarea.value) return;
    if (!window.confirm('Clear the scratch pad? This cannot be undone.')) return;
    textarea.value = '';
    write('');
    say('cleared');
  });
})();
