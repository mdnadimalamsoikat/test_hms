/* HMS common JS - Static Application Files e upload
   User Interface Attributes > JavaScript > File URLs: #APP_FILES#hms.js */
var hms = hms || {};

/* Bangladesh mobile check: 01XXXXXXXXX (11 digit) */
hms.isValidBdPhone = function (v) { return /^(\+?880)?01[3-9]\d{8}$/.test((v || '').replace(/[\s-]/g, '')); };

/* Taka format: hms.tk(12500) -> "৳ 12,500.00" */
hms.tk = function (n) {
  return '\u09F3 ' + Number(n || 0).toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
};

/* Enter chaple next field e jabe (data entry fast) - page load e: hms.enterAsTab() */
hms.enterAsTab = function () {
  // Login page (9999) e kaj korbe na - Enter diye login submit hobe
  if ($v('pFlowStepId') === '9999') { return; }
  $(document).on('keydown', 'input:not([type=button]):not([type=submit]):not([type=checkbox]):not([type=radio])', function (e) {
    if (e.key !== 'Enter') { return; }
    var f = $('input:visible:enabled:not([readonly]),select:visible:enabled,textarea:visible:enabled');
    var i = f.index(this);
    if (i < 0 || i === f.length - 1) { return; }   // shesh field -> normal behavior
    e.preventDefault();
    f.eq(i + 1).focus();
  });
};

/* Duplicate patient check (Ajax Callback process name: CHECK_DUPLICATE) */
hms.checkDuplicate = function () {
  apex.server.process('CHECK_DUPLICATE', { pageItems: '#P10_PHONE_PRIMARY,#P10_FIRST_NAME,#P10_GENDER' }, {
    success: function (d) {
      if (d.patient_id) {
        apex.message.confirm('Ei phone + name e age theke patient ache: ' + d.mrn +
          '\nOi patient er profile khulben?', function (ok) {
            if (ok) { apex.navigation.redirect(d.url); }
          });
      }
    }
  });
};
