class ChartComponent {
    constructor(config) {
        
        this.chart = null;
        this.oppFilters = [];
        this.productFilters = [];
        this.oppHistFilters = [];
        this.dataSet = "";
        this.customizeButtonAdded = false;
        
        for (var key in config) {
            if (config.hasOwnProperty(key)) {
                this[key] = config[key];
            }
        }
        
        this.chartType = config.chartType.toLowerCase();
        
        this.availableColors = [
            '#C62828',
            //'#AD1457',
            '#6A1B9A',
            //'#4527A0',
            '#283593',
            
            //'#1565C0',
            '#0277BD',
            //'#00838F',
            '#00695C',
            //'#2E7D32',
            
            '#558B2F',
            //'#9E9D24',
            '#F9A825',
            //'#FF8F00',
            '#EF6C00',
            
            //'#D84315',
            '#4E342E'
        ];
    }
    
    getFilter(whatFilter, fieldName) {
        console.log(whatFilter);
        console.log(fieldName);
        return whatFilter.find(e => e.field.fullName === fieldName);
    }

    initializeChart() {
        var chartType = this.chartType;
        if (chartType == "line") {
            this.chart = new google.visualization.LineChart(document.getElementById(this.divId));
        } else if (chartType == "bar" || chartType == "barstacked") {
            this.chart = new google.visualization.ColumnChart(document.getElementById(this.divId));
        }
    }

    reloadChart(callback) {
        var oppFilters = this.oppFilters;
        var ownerId = $("#owner").val();
        var managerId = $("#manager").val();
        var selectedRegion = $("#territory").val();
        var globalFilterString = " ";
        var query = 'SELECT Id, OpportunityId, Opportunity.Name, CONVERTCURRENCY(Opportunity.Amount), Opportunity.CreatedDate, Opportunity.Snapshot_Date__c, Opportunity.Converted_Amount__c, Opportunity.StageName, Opportunity.Account.Name, Opportunity.CloseDate, ' + 
                    'CONVERTCURRENCY(Opportunity.Won_Amount_Copy__c), Opportunity.Type, Opportunity.Opportunity_Age__c, Opportunity.Age_from_Created_Date__c, Product2.product_line__c ';
        var self = this;
        
        // Additional fields to be queried?        
        /*if (self.oppHistFilters && self.oppHistFilters.length) {
            self.snapshotReferenceDate = new Date();
            self.snapshotReferenceDate.setMonth(self.snapshotReferenceDate.getMonth() - 3);
            self.snapshotReferenceDate.setDate(2);
            self.snapshotReferenceNow = new Date();
            query +=
                ", (SELECT OpportunityId, CreatedDate, ForecastCategory FROM OpportunityHistories WHERE " +
                self.oppHistFilters.reduce((acc, curr) => [...acc, curr.toSOQLCondition()],[]).join(" AND ") +
                " AND CreatedDate <= " + self.snapshotReferenceDate.toISOString() + " ORDER BY CreatedDate DESC LIMIT 1)";
        }*/
        
        // Object clause
        query += ' FROM OpportunityLineItem WHERE OpportunityId != null';
        
        // Global Filters
        if (ownerId) {
            globalFilterString += " AND Opportunity.OwnerId = '" + ownerId + "'";
        } else if (managerId) {
            globalFilterString += " AND (Opportunity.Owner.ManagerId = '" + managerId + "' OR Opportunity.OwnerId = '" + managerId + "')";
        }
        if (selectedRegion) {
            globalFilterString += " AND Opportunity.Global_Region__c = '" + selectedRegion + "'";
        }
        
        // Time Frame filters
        if (self.timeFrame && self.timeFrameField) {
            globalFilterString +=
                " AND (Opportunity." + self.timeFrameField + " = " + self.timeFrame + (self.timeFrame.includes("LAST_N_FISCAL_QUARTERS") ? " OR Opportunity." + self.timeFrameField + " = THIS_FISCAL_QUARTER" : "") + ")";
        }
        
        // Opportunity Filters
        query +=
            globalFilterString +
            (oppFilters.length ? " AND " + oppFilters.reduce((acc, curr) => [...acc, curr.toSOQLCondition()],[]).join(" AND ") : "");
        
        // Opportunity Product/Product Filters
        if (self.productFilters && self.productFilters.length) {
            query +=
                " AND " +
                self.productFilters.reduce((acc, curr) => [...acc, curr.toSOQLCondition()],[]).join(" AND ") +
                "";
        }
        query += " ORDER BY Opportunity." + self.timeFrameField + " ASC";
        console.log(">>> finalQuery: " + query);
        
		$('#' + self.divId).empty();
        $('#' + self.divId).removeClass('slds-align_absolute-center');
        createLoader($("#" + self.divId));

        conn.query(query, function (err, res) {
            removeLoader($("#" + self.divId));
            if (err) {
                $('#' + self.divId).append('<span id="timedout_' + self.divId + '">A timeout has been reached. Please utilize more filters to avoid querying large data sets.</span>').addClass('slds-align_absolute-center');
                console.error(err);
                return;
            }
            console.log("total : " + res.totalSize);
            console.log("fetched : " + res.records.length);
            console.log("records : ");
            console.log(res.records);
            var returnedData = [];
            console.log(self);
            if (self.yAxis == "winPercentage") {
                returnedData = calculateWinrate(res.records);
            } 
            else if (self.xAxisLabel == "Snapshot Date") {
                returnedData = calculateSnapshots(res.records, self.snapshotReferenceDate, self.snapshotReferenceNow);
            } else {
                returnedData = calculateAverageAge(res.records, self.funnelBy);
            }
            
            if(self.chartType == 'barstacked') {
                drawChartForForecastAccuracy(
                    returnedData, // The value of the hidden field that contains the JSON data
                    self // The chart object in which the chart will be drawn into. It must be initialized first.
                );
            }
            else {
                if(self.useChartJS) {
                    drawChartJS(
                        returnedData, // The value of the hidden field that contains the JSON data
                        self // The chart object in which the chart will be drawn into. It must be initialized first.
                    );
                }
                else {
                    drawChart(
                        returnedData, // The value of the hidden field that contains the JSON data
                        self // The chart object in which the chart will be drawn into. It must be initialized first.
                    );
                }
            }

            callback();
        });
        
        function getSnapshotWrapper(wrapperList, refDate, forecastCategory){
            /*var len = oppWrapList.length;
            for (var i = 0; i < len; i++)
                if (
                    oppWrapList[i].year == year &&
                    oppWrapList[i].quarter == quarter &&
                    oppWrapList[i].type == type
                )
                    return oppWrapList[i];
            return null*/
            
            return wrapperList.filter(e => e.refDate == refDate && e.forecast == forecastCategory);
        }
        
        function calculateSnapshots(oppList, fromDate, toDate) {
            console.log("begin calculateSnapshots: ");
            var returnData = [];
			var len = oppList.length;
            for (var i = 0; i < len; i++) {
                var opp = oppList[i];
                
                if(!opp.OpportunityHistories || !opp.OpportunityHistories.length) {
                    console.log('No Opportunity History record found for this opp!');
                    continue;
                }

                // Calculate the amounts between the two snapshot dates.
                
                var swFrom = getSnapshotWrapper(
                    returnData,
                    fromDate,
                    opp.ForecastCategoryName
                ) || { refDate: fromDate, forecast: opp.ForecastCategoryName, totalConvertedAmount: 0, };
                
                var swTo = getSnapshotWrapper(
                    returnData,
                    toDate,
                    opp.ForecastCategoryName
                ) || { refDate: fromDate, forecast: opp.ForecastCategoryName, totalConvertedAmount: 0, };
                                
                if (opp.OpportunityHistories[0].Amount) swFrom.totalConvertedAmount += opp.Amount;
                
                if (opp.Amount) swTo.totalConvertedAmount += opp.Amount;
            }

            console.log("returnData: ");
            console.log(returnData);
            return returnData;
        }

        function calculateWinrate(oppLineList) {
            console.log("begin calculateWinrate: ");
            var returnData = [];
			var len = oppLineList.length;
            var oppIds = [];
            for (var i = 0; i < len; i++) {
                var ol = oppLineList[i];
                
                // Calculate the win rate per fiscal quarter
                if (ol.Opportunity.Type == null) {
                    ol.Opportunity.Type = "-";
                }
                
                var dateToday = new Date();
                
                var oppCloseDate = new Date(ol.Opportunity.CloseDate);
                var ow = getWrapperUsingType(
                    returnData,
                    oppCloseDate.getFullYear(),
                    getDateQuarter(oppCloseDate),
                    ol.Opportunity.Type
                );
                if (!ow) {
                    ow = {
                        year: oppCloseDate.getFullYear(),
                        quarter: getDateQuarter(oppCloseDate),
                        type: ol.Opportunity.Type,
                        wonOppAmount: 0,
                        allOppAmount: 0,
                        winPercentage: 0
                    };
                    returnData.push(ow);
                }
                if(!oppIds.includes(ol.OpportunityId)) {
                    console.log('adding data to opp: ' + ol.Opportunity.Name);
                    console.log('stage: ' + ol.Opportunity.StageName);
                    console.log('won amt: ' + ol.Opportunity.Won_Amount_Copy__c);
                    oppIds = [...oppIds, ol.OpportunityId];
                    ow.allOppAmount += ol.Opportunity.Amount == null ? 0 : ol.Opportunity.Amount;
                    if (ol.Opportunity.StageName == "Closed Won") {
                        ow.wonOppAmount += ol.Opportunity.Won_Amount_Copy__c;
                    }
                }
            }
            
            console.log('opps queried: ' + oppIds.length);
            console.log(oppIds);
			
            len = returnData.length;
            // Calculate the aggregates for each of the wrappers
            for (var i = 0; i < len; i++) {
                var ow = returnData[i];
                if (ow.allOppAmount != 0) {
                    ow.winPercentage = (ow.wonOppAmount / ow.allOppAmount) * 100;
                }
            }

            console.log("returnData: ");
            console.log(returnData);
            return returnData;
        }

        function calculateAverageAge(oppLineList, funnelBy) {
            console.log('method entry calculateAverageAge');
            var returnData = [];
			var len = oppLineList.length;
            var oppIds = [];
            for (var i = 0; i < len; i++) {
                var ol = oppLineList[i];
                if (!ol.Opportunity[funnelBy]) {
                    continue;
                }
                // Calculate the total age/total converted amount per fiscal quarter
                if (!ol.Product2.product_line__c) {
                    //opp.Product_Line_Name__c = "-";
                    continue;
                }
                var dt = new Date(ol.Opportunity[funnelBy].replace(".000+0000", ""));
                var ow = getWrapperUsingLine(
                    returnData,
                    dt.getFullYear(),
                    getDateQuarter(dt),
                    ol.Product2.product_line__c
                );
                if (!ow) {
                    ow = {
                        year: dt.getFullYear(),
                        quarter: getDateQuarter(dt),
                        productLineName: ol.Product2.product_line__c,
                        totalAge: 0,
                        productLineCount: 0,
                        totalConvertedAmount: 0,
                        totalAgeFromCreatedDate: 0
                    };
                    returnData.push(ow);
                }
                
                if(!oppIds.find(e => e.oppId == ol.OpportunityId && e.prodLineName == ol.Product2.product_line__c)) {
                    oppIds = [...oppIds, {oppId: ol.OpportunityId, prodLineName: ol.Product2.product_line__c}];
                	ow.totalAge += (ol.Opportunity.Opportunity_Age__c < 0 ? 0 : ol.Opportunity.Opportunity_Age__c);
                    ow.totalAgeFromCreatedDate += ol.Opportunity.Age_from_Created_Date__c;
                    ow.productLineCount += 1;
                    if (ol.Opportunity.Converted_Amount__c)
                        ow.totalConvertedAmount += ol.Opportunity.Converted_Amount__c;
                }
                console.log('ow: ');
                console.log(ow);
            }

            // Calculate the aggregates for each of the wrappers
            var len = returnData.length;
            for (var i = 0; i < len; i++) {
                var data = returnData[i];
                data.averageAge = data.productLineCount > 0 ? data.totalAge / data.productLineCount : 0;
                data.averageAgeFromCreatedDate =
                    data.productLineCount > 0 ? data.totalAgeFromCreatedDate / data.productLineCount : 0;
            }

            console.log("returnData: ");
            console.log(returnData);

            return returnData;
        }

        function getWrapperUsingType(oppWrapList, year, quarter, type) {
            var len = oppWrapList.length;
            for (var i = 0; i < len; i++)
                if (
                    oppWrapList[i].year == year &&
                    oppWrapList[i].quarter == quarter &&
                    oppWrapList[i].type == type
                )
                    return oppWrapList[i];
            return null;
        }

        function getWrapperUsingLine(oppWrapList, year, quarter, line) {
            var len = oppWrapList.length;
            for (var i = 0; i < len; i++)
                if (
                    oppWrapList[i].year == year &&
                    oppWrapList[i].quarter == quarter &&
                    oppWrapList[i].productLineName == line
                )
                    return oppWrapList[i];
            return null;
        }

        function getDateQuarter(dt) {
            var month = dt.getMonth() + 1;
            // Quarter 1
            if (month >= 1 && month < 4) {
                return 1;
            }
            // Quarter 2
            else if (month >= 4 && month < 7) {
                return 2;
            }
            // Quarter 3
            else if (month >= 7 && month < 10) {
                return 3;
            }
            // Quarter 4
            else if (month >= 10 && month <= 12) {
                return 4;
            }
            return null;
        }
        
        function drawChartJS(jsonObj, self) {
            console.log('Method entry drawChartJS');
            var grouping = self.grouping;
            var yAxis = self.yAxis;
            if (!self.customizeButtonAdded) {
                
               var menuButton = '' + 
                    '<div class="slds-dropdown-trigger slds-dropdown-trigger_click btn_report_customize" onfocusout="$(this).removeClass(\'slds-is-open\')">' + 
                    '    <button class="slds-button slds-button_icon slds-button_icon-border-filled" aria-haspopup="true" title="Show More" onclick="$(this).parents(\'.slds-dropdown-trigger\').toggleClass(\'slds-is-open\')">' + 
                    '        <svg class="slds-button__icon" aria-hidden="true">' + 
                    '            <use xlink:href="/apexpages/slds/latest/assets/icons/utility-sprite/svg/symbols.svg#down"></use>' + 
                    '        </svg>' + 
                    '        <span class="slds-assistive-text">Show More</span>' + 
                    '    </button>' + 
                    '    <div class="slds-dropdown slds-dropdown_right slds-dropdown_small">' + 
                    '        <ul class="slds-dropdown__list" role="menu" aria-label="Show More">' + 
                    '            <li class="slds-dropdown__item" role="presentation">' + 
                    '                <a href="javascript:void(0);" role="menuitem" tabindex="0" onmousedown="showModal(\'reportModal\', ' + self.divId + ');">' + 
                    '                    <span class="slds-truncate" title="Customize Chart">' + 
                    '                        <svg class="slds-icon slds-icon_x-small slds-icon-text-default slds-m-right_x-small" aria-hidden="true">' + 
                    '                            <use xlink:href="/apexpages/slds/latest/assets/icons/utility-sprite/svg/symbols.svg#settings"></use>' + 
                    '                        </svg>Customize Chart</span>' + 
                    '                </a>' + 
                    '            </li>' + 
                    '            <li class="slds-dropdown__item" role="presentation">' + 
                    '                <a href="javascript:void(0);" role="menuitem" tabindex="-1" onmousedown="window.open(\'/' + self.reportId + '\');">' + 
                    '                    <span class="slds-truncate" title="Go to Report">' + 
                    '                        <svg class="slds-icon slds-icon_x-small slds-icon-text-default slds-m-right_x-small" aria-hidden="true">' + 
                    '                            <use xlink:href="/apexpages/slds/latest/assets/icons/utility-sprite/svg/symbols.svg#link"></use>' + 
                    '                        </svg>Go to Report</span>' + 
                    '                </a>' + 
                    '            </li>' + 
                    '        </ul>' + 
                    '    </div>' + 
                    '</div>';
                
                $('#' + self.divId).before(menuButton);
                self.customizeButtonAdded = true;
            }
            
            chartsLoaded = true;
            
            $('#noresults_' + self.divId).remove();
            if (!jsonObj || !jsonObj.length) {
                $('#' + self.divId).append('<span id="noresults_' + self.divId + '">There are no results returned for this chart.</span>').addClass('slds-align_absolute-center');
                return;
            }
            
            $('#' + self.divId).append('<canvas id="canvas_' + self.divId + '"  style="width: 100%; height: 100%" />');
            
            // Start building ChartJS data set
            var barchartData = { labels: [], datasets: [] };
            var datasetTitles = [];
            
            var years = [], quarters = [];
            
            jsonObj
                .forEach((value) => {
                    if (!years.includes(value.year)) years.push(value.year);
                    if (!quarters.includes(value.quarter)) quarters.push(value.quarter);
                    if (!datasetTitles.includes(value[grouping])) datasetTitles.push(value[grouping]);
                });
            
            datasetTitles.sort();
            years.sort();
            quarters.sort();
            console.log('datasetTitles: ');
            console.log(datasetTitles);

            for (var i = 0; i < years.length; i++) {
                var year = years[i];
                for (var j = 0; j < quarters.length; j++) {
                    if(jsonObj.find(f => f.year == year && f.quarter == quarters[j])) { 
                        barchartData.labels = [...barchartData.labels, 'FY' + (year - 2000) + ' FQ' + quarters[j]]; 
                    }
                }
            }
            
            console.log('>>> barchartData.labels: ');
            console.log(barchartData.labels);
            
            var opts = {
                responsive: true,
                legend: {
                    position: 'bottom',
                },
                /*plugins: {
                  colorschemes: {
                    scheme: 'brewer.Set1-9'
                  }
                },*/
                title: {
                    display: true,
                    text: [self.title, self.subtitle]
                },
                scales: {
                    yAxes: [{
                        position: 'left',
                        ticks: {
                            beginAtZero: true,
                            callback: function(value, index, values) {
                                return value.toLocaleString();
                            }
                        }
                    }]
                },
                tooltips: {
					callbacks: {
                        label: function(tooltipItem, chart){
                            var datasetLabel = chart.datasets[tooltipItem.datasetIndex].label || '';
                            var value = Math.round(tooltipItem.yLabel).toLocaleString();
                            if(self.isCurrency) {
                                value = tooltipItem.yLabel.toLocaleString("en-US",{style:"currency", currency:"USD"});
                            }
                            return datasetLabel + ': ' + value;
                        }
                    }                    
                }
            }
                        
            for (var k = 0; k < datasetTitles.length; k++) {
                //var colorName = colorNames[barchartData.datasets.length % colorNames.length];
                //var dsColor = chartColors[colorName];
                if(self.getFilter(self.productFilters, 'product_line__c') && self.getFilter(self.productFilters, 'product_line__c').value.includes(datasetTitles[k]) && self.getFilter(self.productFilters, 'product_line__c').operator.label === 'not in') {
                    console.log('product line filter: ');
                    console.log(self.getFilter(self.productFilters, 'product_line__c'));
                    continue ;
                }
                
                if(!datasetColors.hasOwnProperty(datasetTitles[k])) {
                    datasetColors[datasetTitles[k]] = self.availableColors[(self.availableColors.length + k) % self.availableColors.length];
                }
                console.log('dataSetColors: ');
                console.log(datasetColors);
                
                var dataset = barchartData.datasets.find(f => f.label == datasetTitles[k]) || {
                    label: datasetTitles[k], 
                    data: [],
                    backgroundColor: datasetColors[datasetTitles[k]], //color(dsColor).rgbString(),
                    borderColor: datasetColors[datasetTitles[k]],
                    borderWidth: 1
                };
                console.log('now evaluating data set ' + datasetTitles[k]);
                var noData = true;
                for (var i = 0; i < years.length; i++) {
                    for (var j = 0; j < quarters.length; j++) {
						if(!jsonObj.find(f => f.year == years[i] && f.quarter == quarters[j])) { 
                            continue ;
                        }
                        console.log('now evaluating for ' + 'FY' + (years[i] - 2000) + ' FQ' + quarters[j]);
                        var opp = jsonObj.find(obj => obj.year == years[i] && obj.quarter == quarters[j] && obj[grouping] == datasetTitles[k]);
                        console.log("opp: ");
                        console.log(opp);
                        if(opp && opp[yAxis]) { 
                            dataset.data = [...dataset.data, opp[yAxis]]; 
                            noData = false;
                        }
                        else {
                            dataset.data = [...dataset.data, null]; 
                        }
                    }
                }
                
                console.log('dataset: ');
                console.log(dataset);
                if(!noData) barchartData.datasets = [...barchartData.datasets, dataset];
            }
            
            if(self.showAveragePerLabels) {
                barchartData.datasets.forEach(e => e.yAxisID = 'A');
                
                opts.scales.yAxes[0].id = 'A';
                opts.scales.yAxes[0].type = 'linear';
                opts.scales.yAxes.push({
                    id: 'B',
                    type: 'linear',
                    position: 'right',
                    ticks: {
                        beginAtZero: true,
                        callback: function(value, index, values) {
                            return value.toLocaleString();
                        }
                    }
                });
                
                var dataset = {
                    label: 'Total Summary', 
                    data: [], 
                    yAxisID: 'B',
                    type: 'line',
                    fill: false,
                    backgroundColor: '#78909C',
                    borderColor: '#78909C',
                    pointBackgroundColor: '#78909C',
                    pointBorderColor: '#78909C'
                };
                
                
                for (var i = 0; i < years.length; i++) {
                    for (var j = 0; j < quarters.length; j++) {
						if(!jsonObj.find(f => f.year == years[i] && f.quarter == quarters[j])) { 
                            continue ;
                        }
                        console.log('now evaluating average for ' + 'FY' + (years[i] - 2000) + ' FQ' + quarters[j]);
                        var oppList = jsonObj.filter(obj => obj.year == years[i] && obj.quarter == quarters[j]);
                        console.log("oppList: ");
                        console.log(oppList);
                        var totals = 0;
                        var count = 0;
                        /*if(opp && opp[yAxis] != null && opp[yAxis] != undefined) { 
                        	var total = oppList.reduce((acc, opp) => acc += opp[yAxis], 0);
                            console.log('total: ' + total);
                            dataset.data = [...dataset.data, total]; 
                            //noData = false;
                        }*/
                        var total = oppList.reduce((acc, opp) => acc += opp[yAxis], 0);
                        console.log('total: ' + total);
                        dataset.data = [...dataset.data, total]; 
                    }
                }
                
                console.log('dataset: ');
                console.log(dataset);
                //if(!noData) 
                barchartData.datasets = [...barchartData.datasets, dataset];
            }
            
            console.log('>>> barchartData: ');
            console.log(barchartData);
            
            
            var ctx = document.getElementById('canvas_' + self.divId).getContext('2d');
            
            if(self.isCurrency) {
                opts.scales.yAxes[0].ticks.callback = function(value, index, values) {
                    return value.toLocaleString("en-US",{style:"currency", currency:"USD"});
                };
                opts.scales.yAxes[1].ticks.callback = function(value, index, values) {
                    return value.toLocaleString("en-US",{style:"currency", currency:"USD"});
                };
            }
            if(self.maxValue) {
                opts.scales = {
                    yAxes: [{
                        display: true,
                        ticks: {
                            min: 0,
                            max: self.maxValue
                        }
                    }]
                }
            }
            self.chart = new Chart(ctx, {
				type: 'bar',
				data: barchartData,
				options: opts
			});
            
            console.log(self);
        }
        
        function drawChartForForecastAccuracy(jsonObj, self) {
            if (!self.customizeButtonAdded) {
                /*var customizeButton = '' +
                    '<button class="slds-button slds-button_icon slds-button_icon-brand btn_report_customize" title="Settings" onclick="showModal(\'reportModal\', ' + self.divId + ');">' +
                    '    <svg class="slds-button__icon" aria-hidden="true">' +
                    '        <use xlink:href="/apexpages/slds/latest/assets/icons/utility-sprite/svg/symbols.svg#settings"></use>' +
                    '    </svg>' +
                    '    <span class="slds-assistive-text">Search</span>' +
                    '</button>';
                $('#' + self.divId).before(customizeButton);
                self.customizeButtonAdded = true;*/
                
                var menuButton = '' + 
                    '<div class="slds-dropdown-trigger slds-dropdown-trigger_click btn_report_customize" onfocusout="$(this).removeClass(\'slds-is-open\')">' + 
                    '    <button class="slds-button slds-button_icon slds-button_icon-border-filled" aria-haspopup="true" title="Show More" onclick="$(this).parents(\'.slds-dropdown-trigger\').toggleClass(\'slds-is-open\')">' + 
                    '        <svg class="slds-button__icon" aria-hidden="true">' + 
                    '            <use xlink:href="/apexpages/slds/latest/assets/icons/utility-sprite/svg/symbols.svg#down"></use>' + 
                    '        </svg>' + 
                    '        <span class="slds-assistive-text">Show More</span>' + 
                    '    </button>' + 
                    '    <div class="slds-dropdown slds-dropdown_right slds-dropdown_small">' + 
                    '        <ul class="slds-dropdown__list" role="menu" aria-label="Show More">' + 
                    '            <li class="slds-dropdown__item" role="presentation">' + 
                    '                <a href="javascript:void(0);" role="menuitem" tabindex="0" onmousedown="showModal(\'reportModal\', ' + self.divId + ');">' + 
                    '                    <span class="slds-truncate" title="Customize Chart">' + 
                    '                        <svg class="slds-icon slds-icon_x-small slds-icon-text-default slds-m-right_x-small" aria-hidden="true">' + 
                    '                            <use xlink:href="/apexpages/slds/latest/assets/icons/utility-sprite/svg/symbols.svg#settings"></use>' + 
                    '                        </svg>Customize Chart</span>' + 
                    '                </a>' + 
                    '            </li>' + 
                    '            <li class="slds-dropdown__item" role="presentation">' + 
                    '                <a href="javascript:void(0);" role="menuitem" tabindex="-1" onmousedown="window.open(\'/' + self.reportId + '\');">' + 
                    '                    <span class="slds-truncate" title="Go to Report">' + 
                    '                        <svg class="slds-icon slds-icon_x-small slds-icon-text-default slds-m-right_x-small" aria-hidden="true">' + 
                    '                            <use xlink:href="/apexpages/slds/latest/assets/icons/utility-sprite/svg/symbols.svg#link"></use>' + 
                    '                        </svg>Go to Report</span>' + 
                    '                </a>' + 
                    '            </li>' + 
                    '        </ul>' + 
                    '    </div>' + 
                    '</div>';
                
                $('#' + self.divId).before(menuButton);
                self.customizeButtonAdded = true;
            }
            
            chartsLoaded = true;
            
            $('#noresults_' + self.divId).remove();
            if (!jsonObj || !jsonObj.length) {
                $('#' + self.divId).append('<span id="noresults_' + self.divId + '">There are no results returned for this chart.</span>').addClass('slds-align_absolute-center');
                return;
            }
            self.initializeChart()
            
            var headers = [];
            var snapshots = [];
            var itms = [];
            // Compose the headers
            jsonObj
                .forEach((value) => {
                    if (!snapshots.includes(value.refDate)) snapshots.push(value.refDate);
                    if (!headers.includes(value[grouping])) headers.push(value[grouping]);
                });
            headers.sort();
            headers.unshift(xAxisLabel);
            console.log('snapshots: ' + snapshots);
            console.log('header size: ' + headers.length);
            console.log('headers: ');
            console.log(headers);

            // Get values for each productLineName for each snapshots
            var quarLen = snapshots.length;
            var headLen = headers.length;
            var year = years[k];
            for (var i = 0; i < quarLen; i++) {
                var snapshotDate = snapshots[i];
                var snapshotData = [snapshot.toLocaleDateString("en-US")];
                var allNull = true;
                for (var j = 1; j < headLen; j++) {
                    var header = headers[j];
                    //console.log('header index: ' + j);
                    var opp = jsonObj.find(obj => obj.year == year && obj.refDate == snapshotDate && obj[grouping] == header);
                    if (opp == undefined) {
                        snapshotData = [...snapshotData, null]
                    }
                    else {
                        snapshotData = [...snapshotData, opp[yAxis]];
                        allNull = false;
                    }
                }
                console.log('snapshotData: ');
                console.log(snapshotData);
                if (!allNull) itms = [...itms, snapshotData];
            }

            var dataArray = [
                headers,
                ...itms
            ];
            var dt2 = google.visualization.arrayToDataTable(dataArray);

            var options = {
                title: self.title,
                //subtitle: self.subtitle,
                legend: {
                    textStyle: {
                        fontSize: 10
                    },
                    position: 'bottom'
                },
                vAxis: {
                    minValue: 0,
                    title: self.yAxisLabel
                },
                hAxis: {
                    title: xAxisLabel
                },
                height: $('#' + self.divId).css('height').replace(/[^-\d\.]/g, ''),
                width: $('#' + self.divId).css('width').replace(/[^-\d\.]/g, ''),
                theme: 'material'
            };
            
            if(self.chartType == "barstacked") {
                options.isStacked = true;
            }
            
            if(self.maxValue) {
                options.vAxis.maxValue = self.maxValue;
            }
            
            console.log('Invoking draw chart...');
            console.log(self.chartType);
            
            self.chart.draw(dt2, options);
            
            google.visualization.events.addListener(self.chart, 'select', function() {
                console.log(self.chart.getSelection());
            });
        }

        function drawChart(jsonObj, self) {
            var grouping = self.grouping;
            var xAxisLabel = self.xAxisLabel;
            var yAxis = self.yAxis;

            if (!self.customizeButtonAdded) {
                var customizeButton = '' +
                    '<button class="slds-button slds-button_icon slds-button_icon-brand btn_report_customize" title="Settings" onclick="showModal(\'reportModal\', ' + self.divId + ');">' +
                    '    <svg class="slds-button__icon" aria-hidden="true">' +
                    '        <use xlink:href="/apexpages/slds/latest/assets/icons/utility-sprite/svg/symbols.svg#settings"></use>' +
                    '    </svg>' +
                    '    <span class="slds-assistive-text">Search</span>' +
                    '</button>';
                $('#' + self.divId).before(customizeButton);
                self.customizeButtonAdded = true;
            }
            
            chartsLoaded = true;

            $('#noresults_' + self.divId).remove();
            if (!jsonObj || !jsonObj.length) {
                $('#' + self.divId).append('<span id="noresults_' + self.divId + '">There are no results returned for this chart.</span>').addClass('slds-align_absolute-center');
                return;
            }
            $('#noresults_' + self.divId).remove();
            self.initializeChart()
            var headers = [];
            var years = [];
            var quarters = [];
            var itms = [];
            // Compose the headers
            jsonObj
                .forEach((value) => {
                    if (!years.includes(value.year)) years.push(value.year);
                    if (!quarters.includes(value.quarter)) quarters.push(value.quarter);
                    if (!headers.includes(value[grouping])) headers.push(value[grouping]);
                });
            years.sort();
            quarters.sort();
            headers.sort();
            headers.unshift(xAxisLabel);
            console.log('years: ' + years);
            console.log('quarters: ' + quarters);
            console.log('header size: ' + headers.length);
            console.log('headers: ');
            console.log(headers);

            // Get values for each productLineName for each quarters
			var yearLen = years.length;
            var quarLen = quarters.length;
            var headLen = headers.length;
            for (var k = 0; k < yearLen; k++) {
                var year = years[k];
                for (var i = 0; i < quarLen; i++) {
                    var quarter = quarters[i];
                    var quarterData = ['FY' + (year - 2000) + ' FQ' + quarter];
                    var allNull = true;
                    for (var j = 1; j < headLen; j++) {
                        var header = headers[j];
                        //console.log('header index: ' + j);
                        var opp = jsonObj.find(obj => obj.year == year && obj.quarter == quarter && obj[grouping] == header);
                        if (opp == undefined) {
                            quarterData = [...quarterData, null]
                        }
                        else {
                            quarterData = [...quarterData, opp[yAxis]];
                            allNull = false;
                        }
                    }
                    console.log('quarterData: ');
                    console.log(quarterData);
                    if (!allNull) itms = [...itms, quarterData]
                }
            }

            var dataArray = [
                headers,
                ...itms
            ];
            var dt2 = google.visualization.arrayToDataTable(dataArray);

            var options = {
                title: self.title,
                //subtitle: self.subtitle,
                legend: {
                    textStyle: {
                        fontSize: 10
                    },
                    position: 'bottom'
                },
                vAxis: {
                    minValue: 0,
                    title: self.yAxisLabel
                },
                hAxis: {
                    title: xAxisLabel
                },
                height: $('#' + self.divId).css('height').replace(/[^-\d\.]/g, ''),
                width: $('#' + self.divId).css('width').replace(/[^-\d\.]/g, ''),
                theme: 'material'
            };
            
            if(self.chartType == "barstacked") {
                options.isStacked = true;
            }
            
            if(self.maxValue) {
                options.vAxis.maxValue = self.maxValue;
            }
            
            console.log('Invoking draw chart...');
            console.log(self.chartType);
            
            self.chart.draw(dt2, options);
            
            google.visualization.events.addListener(self.chart, 'select', function() {
                console.log(self.chart.getSelection());
            });

            /*if (self.chartType == "line") {
            	self.chart.draw(dt2, options);
            } else if (self.chartType == "bar") {
            	self.chart.draw(dt2, options);
            }*/
        }

        function createLoader(parentEle) {
            var spinner =
                '<div id="spinner_' +
                parentEle.attr('id') +
                '" style="height: 100%; background-color: #eee;"><div role="status" class="slds-spinner slds-spinner_brand slds-spinner_large slds-is-relative"> ' +
                '    <span class="slds-assistive-text">Loading</span> ' +
                '    <div class="slds-spinner__dot-a"></div> ' +
                '    <div class="slds-spinner__dot-b"></div> ' +
                "</div></div>";

            parentEle.append(spinner);
        }

        function removeLoader(parentEle) {
            $("#spinner_" + parentEle.attr('id')).remove();
        }
    }
}