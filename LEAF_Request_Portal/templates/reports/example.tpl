<script>
let CSRFToken = '<!--{$CSRFToken}-->';

/*
    This is an example of how LEAF's Query and Grid systems work together to build a spreadsheet.

    The procedure:
    	1. Create a LeafFormQuery
    	2. Configure the grid, by assigning column headings
    	3. Execute the query.
    	
    Once the program has been completed, it can be accessed at the website:
    	https://[your server]/[your folder]/report.php?a=example
    	
*/
async function getData() {
	// Create a new Query
	let query = new LeafFormQuery();
    
	// This would limit results to only find a specific service, by its serviceID
	//query.addTerm('serviceID', '=', 14);
	
	// Find requests that contain the word "example" for indicatorID 16 
	//query.addDataTerm('data', 16, 'LIKE', 'example');
	
	// Find requests that contain data for indicatorID 20, if it's greater or equal than 30000 
    //query.addDataTerm('data', 20, '>=', '30000');
	
	// Find requests that have not passed dependencyID 8 - "the quadrad/pentad/ELT step"
    //query.addDataTerm('dependencyID', 8, '=', 0);
	
    // Find requests that are currently on step #3
    //query.addTerm('stepID', '=', 3);
	
	// Find requests that have NOT been deleted
	query.addTerm('deleted', '=', 0);
	
	// Find requests that have been submitted
	query.addTerm('submitted', '>', 0);
	
	// Find requests that match a specific categoryID
	query.addTerm('categoryID', '=', 'form_12345');

    // Include service data
	query.join('service');
    
    /* Instead of building a query manually, a JSON formatted query generated by the Report Builder
     * may be copied here.
     */
    //query.importQuery({JSON formatted query});
	
    // It's helpful to show a progress indicator if you're planning to run large queries.
    /*
    query.onProgress(numProcessed => {
        document.querySelector('#grid').innerHTML = `Processing ${numProcessed}+ records`;
    });
    */

	// Execute the query
	let result = await query.execute();
    
    // Initialize the Grid
    let formGrid = new LeafFormGrid('grid'); // 'grid' maps to the associated HTML element ID
    
    // This enables the Export button
    formGrid.enableToolbar();
    
    // Required to initialize data for the grid
    formGrid.setDataBlob(result);
    
    // The column headers are configured here
    formGrid.setHeaders([
        {name: 'Service', indicatorID: 'service', editable: false, callback: function(data, blob) {
            $('#'+data.cellContainerID).html(blob[data.recordID].service);
        }},
        {name: 'Title', indicatorID: 'title', callback: function(data, blob) { // The Title field is a bit unique, and must be implemnted this way
            $('#'+data.cellContainerID).html(blob[data.recordID].title);
            $('#'+data.cellContainerID).on('click', function() {
                window.open('index.php?a=printview&recordID='+data.recordID, 'LEAF', 'width=800,resizable=yes,scrollbars=yes,menubar=yes');
            });
        }},
        
        // All other fields based on an indicatorID can use a simplifed syntax
        {name: 'HR Specialist', indicatorID: 256},
        {name: 'Closed-out', editable: false, indicatorID: 299},
        {name: 'Position Title', indicatorID: 355} // Note the last entry should not have an ending comma
    ]);

    // Load and populate the spreadsheet
    formGrid.loadData(Object.keys(result).join(','));
}

async function main() {
	
    getData();

}

// Ensures the webpage has fully loaded before starting the program.
document.addEventListener('DOMContentLoaded', main);
</script>

<div id="grid"></div>
