<%inherit file="../layouts/main.mako"/>
<%!
    import os
    import datetime
    import urllib.parse
    import ntpath

    import sickrage
    from sickrage.subtitles import Subtitles
    from sickrage.core.common import SKIPPED, WANTED, UNAIRED, ARCHIVED, IGNORED, FAILED, DOWNLOADED
    from sickrage.core.common import Quality, qualityPresets, statusStrings, Overview
    from sickrage.core.helpers import anon_url, srdatetime, pretty_file_size, get_size
    from sickrage.core.media.util import showImage
    from sickrage.indexers import IndexerApi
%>

<%namespace file="../includes/modals.mako" import="displayShowModals"/>
<%namespace file="../includes/quality_defaults.mako" import="renderQualityPill"/>

<%block name="modals">
    ${displayShowModals()}
</%block>

<%block name="content">
    <div class="row">
        <div class="col mx-auto">
            <div class="row">
                <!-- Alert -->
                % if show_message:
                    <div class="col-md-12 p-0">
                        <div class="alert alert-info rounded-0 text-center">
                            <strong>${show_message}</strong>
                        </div>
                    </div>
                % endif

                <div class="col-lg-10 mx-auto">
                    <div class="input-group mx-auto" style="width: 30%">
                        <div class="input-group-prepend">
                            <button id="prevShow" class="btn fas fa-arrow-left"></button>
                        </div>
                        <select class="form-control" id="pickShow" title="Change Show">
                            % for show_list_name, show_list in sortedShowLists.items():
                                % if len(show_list) > 1:
                                    <optgroup label="${show_list_name}">
                                % endif
                                % for cur_show in show_list:
                                    <option value="${cur_show.indexer_id}" ${('', 'selected')[cur_show.indexer_id == show.indexer_id]}>${cur_show.name}</option>
                                % endfor
                                % if len(sortedShowLists) > 1:
                                    </optgroup>
                                % endif
                            % endfor
                        </select>
                        <div class="input-group-append">
                            <button id="nextShow" class="btn fas fa-arrow-right"></button>
                        </div>
                    </div>
                    <br/>
                    <div class="row" id="showtitle" data-showname="${show.name}">
                        <div class="col">
                            <h1>
                                ${show.name}
                            </h1>
                        </div>
                        <div class="col">
                            % if seasonResults:
                            % if int(seasonResults[0]) == 0:
                                <% season_special = 1 %>
                            % else:
                                <% season_special = 0 %>
                            % endif
                            % if not sickrage.app.config.display_show_specials and season_special:
                                <% lastSeason = seasonResults.pop(-1) %>
                            % endif
                                <div class="float-right text-left">
                                    % if season_special:
                                    ${_('Display Specials:')}
                                        <a class="inner"
                                           href="${srWebRoot}/toggleDisplayShowSpecials/?show=${show.indexer_id}">
                                            ${('Show', 'Hide')[bool(sickrage.app.config.display_show_specials)]}
                                        </a>
                                    % endif
                                    <br/>
                                    % if (len(seasonResults) > 14):
                                        <select id="seasonJump" class="form-control input-sm" title="Jump to Season"
                                                style="position: relative; top: -4px;">
                                            <option value="jump">Jump to Season</option>
                                            % for seasonNum in seasonResults:
                                                <option value="#season-${seasonNum}"
                                                        data-season="${seasonNum}">${('Specials', 'Season ' + str(seasonNum))[int(seasonNum) > 0]}</option>
                                            % endfor
                                        </select>
                                    % else:
                                        ${_('Season:')}
                                        % for seasonNum in seasonResults:
                                            % if int(seasonNum) == 0:
                                                <a href="#season-${seasonNum}">Specials</a>
                                            % else:
                                                <a href="#season-${seasonNum}">${str(seasonNum)}</a>
                                            % endif
                                            % if seasonNum != seasonResults[-1]:
                                                <span>|</span>
                                            % endif
                                        % endfor
                                    % endif
                                </div>
                            % endif
                        </div>
                    </div>
                    <hr class="bg-light mt-0"/>
                </div>
            </div>

            <div class="row">
                <div class="col-lg-10 mx-auto">
                    <div class="row mb-1">
                        <div class="col my-auto">
                            <div class="row">
                                % if show.imdb_info:
                                    <div class="col-auto">
                                        <% rating_tip = str(show.imdb_info.rating) + " / 10" + " Stars and " + str(show.imdb_info.votes) + " Votes" %>
                                        <span id="imdbstars"
                                              data-imdb-rating="${show.imdb_info.rating}"
                                              title="${rating_tip}"></span>
                                    </div>
                                % endif

                                <div class="col-auto">
                                    (<span>${show.startyear}</span>) -

                                    <span>
                                        % if show.runtime:
                                            ${show.runtime} ${_('minutes')}
                                        % else:
                                            <span style="color: red;"><b>${_('UNKNOWN')}</b></span>
                                        % endif
                                    </span>

                                    % if show.imdb_id:
                                        <a href="${anon_url('http://www.imdb.com/title/', show.imdb_id)}"
                                           rel="noreferrer"
                                           onclick="window.open(this.href, '_blank'); return false;"
                                           title="http://www.imdb.com/title/${show.imdb_id}">
                                            <i class="sickrage-core sickrage-core-imdb"
                                               style="margin-top: -1px; vertical-align:middle;"></i>
                                        </a>
                                    % endif

                                    % if xem_numbering or xem_absolute_numbering:
                                        <a href="${anon_url('http://thexem.de/search?q=', show.name)}"
                                           rel="noreferrer"
                                           onclick="window.open(this.href, '_blank'); return false;"
                                           title="http://thexem.de/search?q-${show.name}">
                                            <i class="sickrage-core sickrage-core-xem"
                                               style="margin-top: -1px; vertical-align:middle;"></i>
                                        </a>
                                    % endif

                                    <a href="${anon_url(IndexerApi(show.indexer).config['show_url'], show.indexer_id)}"
                                       onclick="window.open(this.href, '_blank'); return false;"
                                       title="<% IndexerApi(show.indexer).config["show_url"] + str(show.indexer_id) %>">
                                        <i class="sickrage-core sickrage-core-${IndexerApi(show.indexer).name.lower()}"
                                           style="margin-top: -1px; vertical-align:middle;"></i>
                                    </a>
                                </div>
                            </div>
                            <div class="row">
                                <div class="col">
                                    <ul class="list-group d-inline">
                                        % if not show.imdb_info and show.genre:
                                            % for genre in show.genre.split('|'):
                                                <a href="${anon_url('http://trakt.tv/shows/popular/?genres=', genre.lower())}"
                                                   target="_blank"
                                                   title="View other popular ${genre} shows on trakt.tv.">
                                                    <li class="fas fa-tag fa-1x badge badge-primary p-2"> ${genre}</li>
                                                </a>
                                            % endfor
                                        % elif hasattr(show.imdb_info, 'genre'):
                                            % for genre in show.imdb_info.genre.split(','):
                                                <a href="${anon_url('http://trakt.tv/shows/popular/?genres=', genre.lower())}"
                                                   target="_blank"
                                                   title="View other popular ${genre} shows on trakt.tv.">
                                                    <li class="fas fa-tag badge badge-primary p-1"> ${genre}</li>
                                                </a>
                                            % endfor
                                        % endif
                                    </ul>
                                </div>
                            </div>
                        </div>
                        <div class="col-auto my-auto d-lg-none d-xl-flex">
                            <img class="rounded shadow-lg img-banner"
                                 src="${srWebRoot}${showImage(show.indexer_id, 'banner').url}"/>
                        </div>
                    </div>
                </div>
            </div>

            <div class="row bg-dark border-top border-bottom border-white  pt-2 pb-2">
                <div class="col-lg-10 mx-auto">
                    <div class="row">
                        <div class="col-auto d-none d-lg-block">
                            <img class="shadow-lg rounded"
                                 src="${srWebRoot}${showImage(show.indexer_id, 'poster_thumb').url}"/>
                        </div>

                        <div class="col">
                            <p class="text-viewer">
                                ${show.overview}
                            </p>

                            <table>
                                <tr>
                                    <td class="show-legend">${_('Quality:')}</td>
                                    <td>
                                        <% anyQualities, bestQualities = Quality.split_quality(int(show.quality)) %>
                                        % if show.quality in qualityPresets:
                                            ${renderQualityPill(show.quality)}
                                        % else:
                                            % if anyQualities:
                                                <i>Allowed:</i> ${", ".join([capture(renderQualityPill, x) for x in sorted(anyQualities)])}${("", "<br>")[bool(bestQualities)]}
                                            % endif
                                            % if bestQualities:
                                                <i>Preferred:</i> ${", ".join([capture(renderQualityPill, x) for x in sorted(bestQualities)])}
                                            % endif
                                        % endif
                                    </td>
                                </tr>

                                <tr>
                                    <td class="show-legend">${_('Show Status:')}</td>
                                    <td>${show.status}</td>
                                </tr>

                                % if show.network and show.airs:
                                    <tr>
                                        <td class="show-legend">${_('Originally Airs:')}</td>
                                        <td>${show.airs} ${("<span style='color: red;'><b>(invalid Timeformat)</b></span> ", "")[sickrage.app.tz_updater.test_timeformat(show.airs)]}
                                            on ${show.network}</td>
                                    </tr>
                                % elif show.network:
                                    <tr>
                                        <td class="show-legend">${_('Originally Airs:')}</td>
                                        <td>${show.network}</td>
                                    </tr>
                                % elif show.airs:
                                    <tr>
                                        <td class="show-legend">${_('Originally Airs:')}</td>

                                        <td>${show.airs} ${("<span style='color: red;'><b>(invalid Timeformat)</b></span>", "")[sickrage.app.tz_updater.test_timeformat(show.airs)]}</td>
                                    </tr>
                                % endif

                                <tr>
                                    <td class="show-legend">${_('Default EP Status:')}</td>
                                    <td>${statusStrings[show.default_ep_status]}</td>
                                </tr>

                                <tr>
                                    <td class="show-legend">${_('Location:')}</td>
                                    % if os.path.isdir(showLoc):
                                        <td>${showLoc}</td>
                                    % else:
                                        <td><span style="color: red;">${showLoc}</span> (${_('Missing')})</td>
                                    % endif
                                </tr>

                                <tr>
                                    <td class="show-legend">${_('Size:')}</td>
                                    <td>${pretty_file_size(show.total_size)}</td>
                                </tr>

                                <tr>
                                    <td class="show-legend">${_('Scene Name:')}</td>
                                    <td>${(show.name, " | ".join(show.exceptions))[show.exceptions != 0]}</td>
                                </tr>

                                <tr>
                                    <td class="show-legend">${_('Search Delay:')}</td>
                                    <td>${show.search_delay} day(s)</td>
                                </tr>

                                % if show.rls_require_words:
                                    <tr>
                                        <td class="show-legend">${_('Required Words:')}</td>
                                        <td>${show.rls_require_words}</td>
                                    </tr>
                                % endif

                                % if show.rls_ignore_words:
                                    <tr>
                                        <td class="show-legend">${_('Ignored Words:')}</td>
                                        <td>${show.rls_ignore_words}</td>
                                    </tr>
                                % endif

                                % if bwl and bwl.whitelist:
                                    <tr>
                                        <td class="show-legend">${_('Wanted Group')}${("", "s")[len(bwl.whitelist) > 1]}
                                            :
                                        </td>
                                        <td>${', '.join(bwl.whitelist)}</td>
                                    </tr>
                                % endif

                                % if bwl and bwl.blacklist:
                                    <tr>
                                        <td class="show-legend">${_('Unwanted Group')}${("", "s")[len(bwl.blacklist) > 1]}
                                            :
                                        </td>
                                        <td>${', '.join(bwl.blacklist)}</td>
                                    </tr>
                                % endif
                            </table>
                        </div>

                        <div class="col-auto">
                            <table>
                                <% info_flag = Subtitles().code_from_code(show.lang) if show.lang else '' %>
                                <tr>
                                    <td class="show-legend">${_('Info Language:')}</td>
                                    <td>
                                        <i class="sickrage-flags sickrage-flags-${info_flag}"></i>
                                    </td>
                                </tr>
                                % if sickrage.app.config.use_subtitles:
                                    <tr>
                                        <td class="show-legend">${_('Subtitles:')}</td>
                                        <td>
                                            <i class="fas ${("fa-times text-danger", "fa-check text-success")[bool(show.subtitles)]}"></i>
                                        </td>
                                    </tr>
                                % endif
                                <tr>
                                    <td class="show-legend">${_('Subtitles Metadata:')}</td>
                                    <td>
                                        <i class="fas ${("fa-times text-danger", "fa-check text-success")[bool(show.sub_use_sr_metadata)]}"></i>
                                    </td>
                                </tr>
                                <tr>
                                    <td class="show-legend">${_('Season Folders:')}</td>
                                    <td>
                                        <i class="fas ${("fa-times text-danger", "fa-check text-success")[bool(not show.flatten_folders or sickrage.app.config.naming_force_folders)]}"></i>
                                    </td>
                                </tr>
                                <tr>
                                    <td class="show-legend">${_('Paused:')}</td>
                                    <td>
                                        <i class="fas ${("fa-times text-danger", "fa-check text-success")[bool(show.paused)]}"></i>
                                    </td>
                                </tr>
                                <tr>
                                    <td class="show-legend">${_('Air-by-Date:')}</td>
                                    <td>
                                        <i class="fas ${("fa-times text-danger", "fa-check text-success")[bool(show.air_by_date)]}"></i>
                                    </td>
                                </tr>
                                <tr>
                                    <td class="show-legend">${_('Sports:')}</td>
                                    <td>
                                        <i class="fas ${("fa-times text-danger", "fa-check text-success")[bool(show.is_sports)]}"></i>
                                    </td>
                                </tr>
                                <tr>
                                    <td class="show-legend">${_('Anime:')}</td>
                                    <td>
                                        <i class="fas ${("fa-times text-danger", "fa-check text-success")[bool(show.is_anime)]}"></i>
                                    </td>
                                </tr>
                                <tr>
                                    <td class="show-legend">${_('DVD Order:')}</td>
                                    <td>
                                        <i class="fas ${("fa-times text-danger", "fa-check text-success")[bool(show.dvdorder)]}"></i>
                                    </td>
                                </tr>
                                <tr>
                                    <td class="show-legend">${_('Scene Numbering:')}</td>
                                    <td>
                                        <i class="fas ${("fa-times text-danger", "fa-check text-success")[bool(show.scene)]}"></i>
                                    </td>
                                </tr>
                                <tr>
                                    <td class="show-legend">${_('Skip Downloaded:')}</td>
                                    <td>
                                        <i class="fas ${("fa-times text-danger", "fa-check text-success")[bool(show.skip_downloaded)]}"></i>
                                    </td>
                                </tr>
                            </table>
                        </div>
                    </div>
                </div>
            </div>

            <div class="row bg-dark border-top border-bottom border-white p-1">
                <div class="col-lg-10 mx-auto">
                    <div class="row">
                        <div class="col">
                            <div class="d-inline-flex" id="checkboxControls">
                                <h5 class="my-auto">
                                    <span class="badge missed">
                                        <input type="checkbox" id="missed" checked/>
                                        ${_('Missed:')} <b>${epCounts[Overview.MISSED]}</b>
                                    </span>
                                    <span class="badge wanted">
                                        <input type="checkbox" id="wanted" checked/>
                                        ${_('Wanted:')} <b>${epCounts[Overview.WANTED]}</b>
                                    </span>
                                    <span class="badge qual">
                                        <input type="checkbox" id="qual" checked/>
                                        ${_('Low Quality:')} <b>${epCounts[Overview.QUAL]}</b>
                                    </span>
                                    <span class="badge good">
                                        <input type="checkbox" id="good" checked/>
                                        ${_('Downloaded:')} <b>${epCounts[Overview.GOOD]}</b>
                                    </span>
                                    <span class="badge skipped">
                                        <input type="checkbox" id="skipped" checked/>
                                        ${_('Skipped:')} <b>${epCounts[Overview.SKIPPED]}</b>
                                    </span>
                                    <span class="badge snatched">
                                        <input type="checkbox" id="snatched" checked/>
                                        <% total_snatched = epCounts[Overview.SNATCHED] + epCounts[Overview.SNATCHED_PROPER] + epCounts[Overview.SNATCHED_BEST] %>
                                        ${_('Snatched:')} <b>${total_snatched}</b>
                                    </span>
                                </h5>
                            </div>
                        </div>

                        <div class="col-auto my-auto">
                            <div class="btn-group-sm">
                                <button class="btn" id="popover">
                                    ${_('Filter Columns')} <b class="fas fa-caret-down"></b>
                                </button>
                                <button class="btn seriesCheck">
                                    ${_('Select Episodes')}
                                </button>
                                <button class="btn clearAll">
                                    ${_('Clear All')}
                                </button>
                            </div>
                        </div>

                        <div class="col-auto my-auto">
                            <div class="input-group input-group-sm">
                                <select id="statusSelect" title="Change selected episode statuses"
                                        class="form-control">
                                    <% availableStatus = [WANTED, SKIPPED, IGNORED, FAILED] %>
                                    % if sickrage.app.developer:
                                        <% availableStatus.append(UNAIRED) %>
                                    % endif
                                    % for curStatus in availableStatus + sorted(Quality.DOWNLOADED) + sorted(Quality.ARCHIVED):
                                        % if curStatus not in [DOWNLOADED, ARCHIVED]:
                                            <option value="${curStatus}">${statusStrings[curStatus]}</option>
                                        % endif
                                    % endfor
                                </select>
                                <div class="input-group-append">
                                    <button id="changeStatus" class="btn fas fa-play"></button>
                                </div>
                            </div>
                            <input type="hidden" id="showID" value="${show.indexer_id}"/>
                            <input type="hidden" id="indexer" value="${show.indexer}"/>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <div class="row">
    <div class="col-lg-10 mx-auto">
    <div class="row">
    <div class="col-md-12">
        <% curSeason = -1 %>
        <% odd = 0 %>
        % for episode_object in episode_objects:
            <%
                epStr = str(episode_object.season) + "x" + str(episode_object.episode)
                if not epStr in epCats:
                    continue

                if not sickrage.app.config.display_show_specials and int(episode_object.season) == 0:
                    continue

                scene = False
                scene_anime = False
                if not show.air_by_date and not show.is_sports and not show.is_anime and show.is_scene:
                                scene = True
                elif not show.air_by_date and not show.is_sports and show.is_anime and show.is_scene:
                                scene_anime = True

                (dfltSeas, dfltEpis, dfltAbsolute) = (0, 0, 0)
                if (episode_object.season, episode_object.episode) in xem_numbering:
                                (dfltSeas, dfltEpis) = xem_numbering[(episode_object.season, episode_object.episode)]

                if episode_object.absolute_number in xem_absolute_numbering:
                                dfltAbsolute = xem_absolute_numbering[episode_object.absolute_number]

                if episode_object.absolute_number in scene_absolute_numbering:
                                scAbsolute = scene_absolute_numbering[episode_object.absolute_number]
                                dfltAbsNumbering = False
                else:
                                scAbsolute = dfltAbsolute
                                dfltAbsNumbering = True

                if (episode_object.season, episode_object.episode) in scene_numbering:
                                (scSeas, scEpis) = scene_numbering[(episode_object.season, episode_object.episode)]
                                dfltEpNumbering = False
                else:
                                (scSeas, scEpis) = (dfltSeas, dfltEpis)
                                dfltEpNumbering = True

                epLoc = episode_object.location
                if epLoc and show.location and epLoc.lower().startswith(show.location.lower()):
                                epLoc = epLoc[len(show.location)+1:]
            %>

            % if int(episode_object.season) != curSeason:
            <% curSeason = int(episode_object.season) %>
            % if episode_object.season != episode_objects[0].season:
                </tbody>
                </table>
            </div>
            </div>
            </div>
            % endif

                <div class="row">
                    <div class="col">
                        <br/>
                        <h3 style="display: inline;">
                            <a name="season-${episode_object.season}"></a>
                            ${(_("Specials"), _("Season") + ' ' + str(episode_object.season))[int (episode_object.season) > 0]}
                        </h3>
                        % if not sickrage.app.config.display_all_seasons:
                            % if curSeason == -1:
                                <button id="showseason-${episode_object.season}" type="button"
                                        class="btn btn-sm text-right"
                                        data-toggle="collapse" data-target="#collapseSeason-${episode_object.season}"
                                        aria-expanded="true">${_('Hide Episodes')}</button>
                            %else:
                                <button id="showseason-${episode_object.season}" type="button"
                                        class="btn btn-sm text-right"
                                        data-toggle="collapse"
                                        data-target="#collapseSeason-${episode_object.season}">${_('Show Episodes')}</button>
                            %endif
                        % endif
                    </div>
                </div>

            <div class="row">
            <div class="col-md-12">
            <div class="table-responsive">
            <table id="${("showTable", "animeTable")[bool(show.is_anime)]}" class="table displayShowTable">
                <thead class="thead-dark">
                <tr class="seasoncols">
                    <th data-sorter="false" data-priority="critical" class="col-checkbox">
                        <input type="checkbox" class="seasonCheck" id="${episode_object.season}"/>
                    </th>
                    <th data-sorter="false" class="col-metadata">${_('NFO')}</th>
                    <th data-sorter="false" class="col-metadata">${_('TBN')}</th>
                    <th data-sorter="false" class="col-ep episode">${_('Episode')}</th>
                    <th data-sorter="false" ${("class=\"col-ep columnSelector-false\"", "class=\"col-ep\"")[bool(show.is_anime)]}>${_('Absolute')}</th>
                    <th data-sorter="false" ${("class=\"col-ep columnSelector-false\"", "class=\"col-ep\"")[bool(scene)]}>${_('Scene')}</th>
                    <th data-sorter="false" ${("class=\"col-ep columnSelector-false\"", "class=\"col-ep\"")[bool(scene_anime)]}>${_('Scene Absolute')}</th>
                    <th data-sorter="false" class="col-name">${_('Name')}</th>
                    <th data-sorter="false" class="col-ep columnSelector-false size">${_('Size')}</th>
                    <th data-sorter="false" class="col-airdate">${_('Airdate')}</th>
                    <th data-sorter="false" ${("class=\"col-ep columnSelector-false\"", "class=\"col-ep\"")[bool(sickrage.app.config.download_url)]}>${_('Download')}</th>
                    <th data-sorter="false" ${("class=\"col-ep columnSelector-false\"", "class=\"col-ep\"")[bool(sickrage.app.config.use_subtitles)]}>${_('Subtitles')}</th>
                    <th data-sorter="false" class="col-status">${_('Status')}</th>
                    % if len(sickrage.app.search_providers.enabled()):
                        <th data-sorter="false" class="col-search">${_('Search')}</th>
                    % endif
                </tr>
                </thead>

            <tbody
                % if sickrage.app.config.display_all_seasons == False:
                    class="collapse${("", " in")[curSeason == -1]}"
                    id="collapseSeason-${episode_object.season}"
                % endif
            >
            % endif
            <tr class="${Overview.overviewStrings[epCats[epStr]]} season-${curSeason} seasonstyle font-weight-bold text-dark"
                id="S${str(episode_object.season)}E${str(episode_object.episode)}">

                <td class="table-fit col-checkbox">
                    % if int(episode_object.status) != UNAIRED:
                        <input type="checkbox" class="epCheck"
                               id="${str(episode_object.season)}x${str(episode_object.episode)}"
                               name="${str(episode_object.season)}x${str(episode_object.episode)}" title=""/>
                    % endif
                </td>

                <td class="table-fit">
                    <i class="fas ${("fa-times", "fa-check")[episode_object.hasnfo]}"></i>
                </td>

                <td class="table-fit">
                    <i class="fas ${("fa-times", "fa-check")[episode_object.hastbn]}"></i>
                </td>

                <td class="table-fit">
                    <%
                        text = str(episode_object.episode)
                        if epLoc != '' and epLoc is not None:
                                    text = '<span title="' + epLoc + '" class="badge badge-dark">' + text + "</span>"
                    %>
                        ${text}
                </td>

                <td class="table-fit">${episode_object.absolute_number}</td>

                <td class="table-fit">
                    <input placeholder="${str(dfltSeas)}x${str(dfltEpis)}" size="6"
                           maxlength="8"
                           class="sceneSeasonXEpisode form-control input-scene"
                           data-for-season="${episode_object.season}"
                           data-for-episode="${episode_object.episode}"
                           id="sceneSeasonXEpisode_${show.indexer_id}_${str(episode_object.season)}_${str(episode_object.episode)}"
                           title="Change the value here if scene numbering differs from the indexer episode numbering"
                        % if dfltEpNumbering:
                           value=""
                        % else:
                           value="${str(scSeas)}x${str(scEpis)}"
                        % endif
                           style="padding: 0; text-align: center; max-width: 60px;"/>
                </td>

                <td class="table-fit">
                    <input placeholder="${str(dfltAbsolute)}" size="6" maxlength="8"
                           class="sceneAbsolute form-control d-inline input-scene"
                           data-for-absolute="${episode_object.absolute_number}"
                           id="sceneAbsolute_${show.indexer_id}_${str(episode_object.absolute_number)}"
                           title="Change the value here if scene absolute numbering differs from the indexer absolute numbering"
                        % if dfltAbsNumbering:
                           value=""
                        % else:
                           value="${str(scAbsolute)}"
                        % endif
                           style="padding: 0; text-align: center; max-width: 60px;"/>
                </td>

                <td class="col-name">
                    <i id="plot_info_${str(show.indexer_id)}_${str(episode_object.season)}_${str(episode_object.episode)}"
                       class="fas fa-info-circle" title="${episode_object.description}"></i>
                    ${episode_object.name}
                </td>

                <td class="table-fit text-nowrap col-ep">
                    ${pretty_file_size(episode_object.file_size)}
                </td>

                <td class="table-fit col-airdate">
                    <% airDate = episode_object.airdate %>

                    % if airDate.year >= 1970 or show.network:
                        <% airDate = srdatetime.SRDateTime(sickrage.app.tz_updater.parse_date_time(episode_object.airdate, show.airs, show.network), convert=True).dt %>
                    % endif

                    <time datetime="${airDate.isoformat()}" class="date text-nowrap">
                        ${srdatetime.SRDateTime(airDate).srfdatetime()}
                    </time>
                </td>

                <td class="table-fit">
                    % if sickrage.app.config.download_url and episode_object.location:
                    <%
                        filename = episode_object.location
                        for rootDir in sickrage.app.config.root_dirs.split('|'):
                                                if rootDir.startswith('/'):
                                                    filename = filename.replace(rootDir, "")
                        filename = sickrage.app.config.download_url + urllib.parse.quote(filename.encode('utf8'))
                    %>
                        <div style="text-align: center;">
                            <a href="${filename}">${_('Download')}</a>
                        </div>
                    % endif
                </td>

                <td class="table-fit col-subtitles">
                    % for flag in (episode_object.subtitles or '').split(','):
                        % if Subtitles().name_from_code(flag).lower() != 'undetermined':
                            % if flag.strip() != 'und':
                                <i class="sickrage-flags sickrage-flags-${flag}"
                                   title="${Subtitles().name_from_code(flag)}"></i>
                            % else:
                                <i class="sickrage-flags sickrage-flags-${flag}"
                                   title="${Subtitles().name_from_code(flag)}"></i>
                            % endif
                        % else:
                            <i class="sickrage-flags sickrage-flags-unknown" title="${_('Unknown')}"></i>
                        % endif
                    % endfor
                </td>

                <% curStatus, curQuality = Quality.split_composite_status(int(episode_object.status)) %>
                % if curQuality != Quality.NONE:
                    <td class="table-fit text-nowrap col-status">${statusStrings[curStatus]} ${renderQualityPill(curQuality)}</td>
                % else:
                    <td class="table-fit text-nowrap col-status">${statusStrings[curStatus]}</td>
                % endif

                % if len(sickrage.app.search_providers.enabled()):
                    <td class="table-fit col-search">
                        % if int(episode_object.season) != 0:
                            % if ( int(episode_object.status) in Quality.SNATCHED + Quality.DOWNLOADED ):
                                <a class="epRetry"
                                   id="${str(show.indexer_id)}x${str(episode_object.season)}x${str(episode_object.episode)}"
                                   name="${str(show.indexer_id)}x${str(episode_object.season)}x${str(episode_object.episode)}"
                                   href="${srWebRoot}/home/retryEpisode?show=${show.indexer_id}&amp;season=${episode_object.season}&amp;episode=${episode_object.episode}">
                                    <i class="fas fa-sync" title="${_('Retry Download')}"></i>
                                </a>
                            % else:
                                <a class="epSearch"
                                   id="${str(show.indexer_id)}x${str(episode_object.season)}x${str(episode_object.episode)}"
                                   name="${str(show.indexer_id)}x${str(episode_object.season)}x${str(episode_object.episode)}"
                                   href="${srWebRoot}/home/searchEpisode?show=${show.indexer_id}&amp;season=${episode_object.season}&amp;episode=${episode_object.episode}">
                                    <i class="fas fa-search" title="${_('Manual Search')}"></i>
                                </a>
                            % endif
                        % endif
                        % if sickrage.app.config.use_subtitles and show.subtitles and episode_object.location and frozenset(Subtitles().wanted_languages()).difference(episode_object.subtitles.split(',')):
                            <a class="epSubtitlesSearch"
                               href="${srWebRoot}/home/searchEpisodeSubtitles?show=${show.indexer_id}&amp;season=${episode_object.season}&amp;episode=${episode_object.episode}">
                                <i class="fas fa-comment" title="${_('Subtitles Search')}"></i>
                            </a>
                        % endif
                    </td>
                % endif
            </tr>
        % endfor
    </tbody>
    </table>
    </div>
    </div>
    </div>
    </div>
    </div>
</%block>