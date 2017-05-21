//Fixed Menu

var menu = $('nav#menu');

var watcher = scrollMonitor.create( menu );

watcher.lock();

watcher.stateChange(function() {
    $(menu).toggleClass('scrolled', this.isAboveViewport)
});

// Travel page map initialization
$(document).ready(function () {
    /*
    $('.jvectormaps').each(function (map) {

    });
    */

    var createScript = function(url, callback) {
        var scr = document.createElement('script');
        scr.src = url;
        scr.onload = callback;
        document.body.appendChild(scr);
    };

    var $worldMap = $('#jvectormap-travel-world-map');
    var $usMap = $('#jvectormap-travel-usa-map');
    var visitedColor = '#afc793';
    var highlightedColor = '#826d97';
    var unvisitedColor = '#fff';
    var visitedCountries = {
        BE: '1',
        CA: '1',
        CN: '1',
        CR: '1',
        CU: '1',
        DK: '1',
        ES: '1',
        FR: '1',
        GB: '1',
        HK: '1',
        ID: '1',
        JP: '1',
        KR: '1',
        MM: '1',
        MO: '1',
        MX: '1',
        MY: '1', 
        NL: '1',
        NZ: '1',
        PR: '1',       
        SE: '1',
        SG: '1',
        TH: '1',
        TW: '1',
        US: '1',
    };
    var visitedStates = {
        'US-AK': '1',
        'US-AL': '1',
        'US-AZ': '1',
        'US-CA': '1',
        'US-CO': '1',
        'US-FL': '1',
        'US-HI': '1',
        'US-ID': '1',
        'US-IL': '1',
        'US-KY': '1',
        'US-LA': '1',
        'US-MA': '1',
        'US-MD': '1',
        'US-MI': '1',
        'US-MN': '1',
        'US-MS': '1',
        'US-NC': '1',
        'US-NJ': '1',
        'US-NM': '1',
        'US-NV': '1',
        'US-NY': '1',
        'US-OH': '1',
        'US-OR': '1',
        'US-PA': '1',
        'US-SC': '1',
        'US-TX': '1',
        'US-UT': '1',
        'US-WA': '1',
        'US-WI': '1',
        'US-WY': '1',
    };

    if ($worldMap.length || $usMap.length) {
        createScript('/js/jvectormap/jquery-jvectormap-2.0.3.min.js', function () {
            createScript('/js/jvectormap/jquery-jvectormap.js', function () {
                if ($worldMap.length) {
                    createScript('/js/jvectormap/jquery-jvectormap-world-mill.js', function () {
                        $worldMap.vectorMap({
                            map: 'world_mill',
                            backgroundColor: unvisitedColor,
                            regionStyle: {
                                initial: {
                                    'fill': 'white',
                                    'fill-opacity': 1,
                                    'stroke': highlightedColor,
                                    'stroke-width': 1,
                                    'stroke-opacity': 0.75
                                },
                                hover: {
                                    'fill': highlightedColor,
                                    'fill-opacity': 1,
                                    'cursor': 'pointer'
                                },
                                selected: {
                                    'fill': 'yellow'
                                },
                                selectedHover: {
                                }
                            },
                            series: {
                                regions: [{
                                    scale: {
                                        '1': visitedColor,
                                    },
                                    attributes: 'fill',
                                    values: visitedCountries,
                                }]
                            },
                        });
                    });
                }

                if ($usMap.length) {
                    createScript('/js/jvectormap/jquery-jvectormap-us-aea.js', function () {
                        $usMap.vectorMap({ 
                            map: 'us_aea',
                            backgroundColor: unvisitedColor,
                            regionStyle: {
                                initial: {
                                    'fill': 'white',
                                    'fill-opacity': 1,
                                    'stroke': highlightedColor,
                                    'stroke-width': 1,
                                    'stroke-opacity': 0.75
                                },
                                hover: {
                                    'fill': highlightedColor,
                                    'fill-opacity': 1,
                                    'cursor': 'pointer'
                                },
                                selected: {
                                    'fill': 'yellow'
                                },
                                selectedHover: {
                                }
                            },
                            series: {
                                regions: [{
                                    scale: {
                                        '1': visitedColor,
                                    },
                                    attributes: 'fill',
                                    values: visitedStates,
                                }]
                            },
                        });
                    });
                }
            });
        });
    }
});