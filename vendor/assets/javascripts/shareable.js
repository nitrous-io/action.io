/*
 * Shareable.JS
 * Unobstrusive social sharing buttons
 * Ideal for the use in pages rendered in client-side.
 *
 * Copyright 2013, Nitrous
 * https://nitrous.io
 *
 * Licensed under the MIT license:
 * http://www.opensource.org/licenses/MIT
 */

var Shareable = (function () {
  return {
    initTwitterButton: function(d,s,id) {
      var js,fjs=d.getElementsByTagName(s)[0],p=/^http:/.test(d.location)?'http':'https';if(!d.getElementById(id)){js=d.createElement(s);js.id=id;js.src=p+'://platform.twitter.com/widgets.js';fjs.parentNode.insertBefore(js,fjs);}
    },
    initGooglePlusButton: function() {
      var po = document.createElement('script'); po.type = 'text/javascript'; po.async = true;
      po.src = 'https://apis.google.com/js/plusone.js';
      var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(po, s);
    },
    initFacebookButton: function(d, s, id) {
      var fbRoot = document.createElement('div');
      fbRoot.id = "fb-root";
      document.body.appendChild(fbRoot);

      var js, fjs = d.getElementsByTagName(s)[0];
      if (d.getElementById(id)) return;
      js = d.createElement(s); js.id = id;
      js.src = "//connect.facebook.net/en_US/all.js#xfbml=1";
      fjs.parentNode.insertBefore(js, fjs);
    }
  }
})(this);
