class Filter {
    constructor(obj, field, operator, value) {
        // data validation
        if(!Filter.ops.find(e => e.label === operator)) {
            console.error('No matching operator for: ' + operator);
            return ;
        }
        console.log('field: ');
        console.log(field);
        var fieldObj;
        if(!field) {
            fieldObj = metadata[obj].fields[0];
        }
        else {
            if(!metadata[obj].fields.find(e => e.fullName === field)) console.error('No such field ' + field + ' for object ' + obj);
            fieldObj = metadata[obj].fields.find(e => e.fullName === field);
        }
        
        var operatorObj = Filter.ops.find(e => e.label === operator);
        console.log(operatorObj);
        if(!operatorObj.allowableTypes.some(e => e === fieldObj.type)) {
            console.error('Invalid filter! ');
            console.log(fieldObj);
            console.log(operator);
            console.log(value);
            return ;
        }
        if(Filter.ops.find(e => e.label === operator).value == "IN" && value.constructor !== Array) {
            console.error('Invalid operator IN for ' + operator);
            return ;
        }
        this.objectName = obj;
        this.objectMetadata = metadata[obj];
        this.field = fieldObj;
        this.operator = Filter.ops.find(e => e.label === operator);
        this.value = value;
    }
    
    isEmpty() {
        return !(this.objectMetadata && this.field && this.operator && this.value !== null);
    }
    
    setField(fieldAPIname) {
        if(!this.objectMetadata.fields.find(e => e.fullName === fieldAPIname)) return console.error('Invalid field ' + fieldAPIName + ' for object ' + this.objectMetadata.fullName);
        this.field = this.objectMetadata.fields.find(e => e.fullName === fieldAPIname);
    }
    
    setOperator(opLabel) {
        if(!Filter.ops.find(e => e.label === opLabel)) return console.error('Invalid field ' + fieldAPIName + ' for object ' + this.objectMetadata.fullName);
        this.operator = Filter.ops.find(e => e.label === opLabel);
    }
    
    setValue(val) {
        if(this.field.type === 'Checkbox') {
            this.value = (val === true || val == 'true');
            console.log(this);
        }
        else {
        	this.value = this.operator.value == "IN" && val.constructor !== Array ? val.split(',') : val;
        }
    }
    
    static ops = [
        { label: "equals", value: "=", allowableTypes: ["Currency", "Lookup", "Text", "Percent", "Date", "Checkbox", "Picklist", "Number", "DateTime", "LongTextArea", "Html", "Summary", "TextArea", "MultiselectPicklist", "Email", "AutoNumber", "Url"] },
        { label: "not equal to", value: "!=", allowableTypes: ["Currency", "Lookup", "Text", "Percent", "Date", "Checkbox", "Picklist", "Number", "DateTime", "LongTextArea", "Html", "Summary", "TextArea", "MultiselectPicklist", "Email", "AutoNumber", "Url"] },
        { label: "greater than", value: ">", allowableTypes: ["Currency", "Percent", "Date", "Number", "DateTime", "Summary"] },
        { label: "less than", value: "<", allowableTypes: ["Currency", "Percent", "Date", "Number", "DateTime", "Summary"] },
        { label: "greater than or equal to", value: ">=", allowableTypes: ["Currency", "Percent", "Date", "Number", "DateTime", "Summary"] },
        { label: "less than or equal to", value: "<=", allowableTypes: ["Currency", "Percent", "Date", "Number", "DateTime", "Summary"] },
        { label: "contains", value: "LIKE", allowableTypes: ["Text", "Lookup", "Picklist", "LongTextArea", "Html", "TextArea", "Email", "Url"] },
        { label: "does not contain", value: "LIKE", allowableTypes: ["Text", "Lookup", "Picklist", "LongTextArea", "Html", "TextArea", "Email", "Url"] },
        { label: "starts with", value: "LIKE", allowableTypes: ["Text", "Lookup", "Picklist", "LongTextArea", "Html", "TextArea", "Email", "Url"] },
        { label: "ends with", value: "LIKE", allowableTypes: ["Text", "Lookup", "Picklist", "LongTextArea", "Html", "TextArea", "Email", "Url"] },
        { label: "not in", value: "IN", allowableTypes: ["Currency", "Lookup", "Text", "Percent", "Date", "Checkbox", "Picklist", "Number", "DateTime", "LongTextArea", "Html", "Summary", "TextArea", "MultiselectPicklist", "Email", "AutoNumber", "Url"] },
        { label: "in", value: "IN", allowableTypes: ["Currency", "Lookup", "Text", "Percent", "Date", "Checkbox", "Picklist", "Number", "DateTime", "LongTextArea", "Html", "Summary", "TextArea", "MultiselectPicklist", "Email", "AutoNumber", "Url"] }
    ];
    
    toSOQLCondition() {
        var fieldName = (this.objectName == 'Product2' ? 'Product2.' : (this.objectName == 'Opportunity' ? 'Opportunity.' : '')) + this.field.fullName;
        if(this.field.type == "Lookup") fieldName = fieldName.replace('Id', '.Name');
        var opString = this.operator.value;
        var valString = '';
        var start = ["not in", "does not contain"].includes(this.operator.label) ? '(NOT ' : '';
        var end = ["not in", "does not contain"].includes(this.operator.label) ? ')' : '';
        
        if(this.value.constructor === Array) {
            if(["Currency", "Percent", "Date", "Number", "DateTime", "Summary", "Checkbox"].includes(this.field.type)) {
                valString = '(' + this.value.join(', ') + ')';
            }
            else {
                valString = '(\'' + this.value.join('\', \'') + '\')';
            }
        }
        else {
            if(this.value === true || this.value === false) {
                valString = this.value;
            }
            else {
                var sanitizedValue = this.value.replace('\'', '\\\'');
                if(["Currency", "Percent", "Date", "Number", "DateTime", "Summary"].includes(this.field.type)) {
                    valString = sanitizedValue;
                }
                else {
                    valString += '\'';
                    if(["contains","does not contain","starts with"].includes(this.operator.label)) valString += '%';
                    valString += sanitizedValue;
                    if(["contains","does not contain","ends with"].includes(this.operator.label)) valString += '%';
                    valString += '\'';
                }
            }
        }
        return start + fieldName + ' ' + opString + ' ' + valString + end;
    }
}