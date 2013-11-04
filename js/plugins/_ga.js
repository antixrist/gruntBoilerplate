
// Google Analytics: change UA-XXXXX-X to be your site's ID.
var GAsiteID = window.GAsiteID || 'UA-XXXXX-X';

if (GAsiteID != 'UA-XXXXX-X') {

	// require Google Analytics script
	(function(b, o, i, l, e, r) {
		b.GoogleAnalyticsObject = l;
		b[l] || (b[l] = function() {
			(b[l].q = b[l].q || []).push(arguments)
		});
		b[l].l = +new Date;
		e = o.createElement(i);
		r = o.getElementsByTagName(i)[0];
		e.src = '//www.google-analytics.com/analytics.js';
		r.parentNode.insertBefore(e, r)
	}(window, document, 'script', 'ga'));
	ga('create', GAsiteID);
	ga('send', 'pageview');

	/*
	 * Log all jQuery AJAX requests to Google Analytics
	 * See: http://www.alfajango.com/blog/track-jquery-ajax-requests-in-google-analytics/
	 */
	if (typeof $ === 'function') {
		$(document).ajaxSend(function(event, xhr, settings) {
			_gaq.push(['_trackPageview', settings.url]);
		});
	}

	// Track JavaScript errors in Google Analytics
	var link = function(href) {
		var a = window.document.createElement('a');
		a.href = href;
		return a;
	};
	window.onerror = function(message, file, line, column) {
		var host = link(file).hostname;
		_gaq.push([
			'_trackEvent', (host == window.location.hostname || host == undefined || host == '' ? '' : 'external ') + 'error',
			message, file + ' LINE: ' + line + (column ? ' COLUMN: ' + column : ''), undefined, undefined, true
		]);
	};

	// Track page scroll
	$(function() {
		var isDuplicateScrollEvent,
			scrollTimeStart = new Date,
			$window = $(window),
			$document = $(document),
			scrollPercent;

		$window.scroll(function() {
			scrollPercent = Math.round(100 * ($window.height() + $window.scrollTop()) / $document.height());
			if (scrollPercent > 90 && !isDuplicateScrollEvent) { //page scrolled to 90%
				isDuplicateScrollEvent = 1;
				_gaq.push(['_trackEvent', 'scroll',
					'Window: ' + $window.height() + 'px; Document: ' + $document.height() + 'px; Time: ' + Math.round((new Date - scrollTimeStart) / 1000, 1) + 's',
					undefined, undefined, true
				]);
			}
		});
	});
}