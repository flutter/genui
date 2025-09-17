export function validateSchema(data: any, schemaName: string): string[] {
    const errors: string[] = [];

    switch (schemaName) {
        case 'stream_header.json':
            validateStreamHeader(data, errors);
            break;
        case 'component_update.json':
            validateComponentUpdate(data, errors);
            break;
        case 'data_model_update.json':
            validateDataModelUpdate(data, errors);
            break;
        case 'begin_rendering.json':
            validateBeginRendering(data, errors);
            break;
        default:
            errors.push(`Unknown schema for validation: ${schemaName}`);
    }

    return errors;
}

function validateStreamHeader(data: any, errors: string[]) {
    if (!data.version) {
        errors.push("StreamHeader must have a 'version' property.");
    }
    const allowed = ['version'];
    for (const key in data) {
        if (!allowed.includes(key)) {
            errors.push(`StreamHeader has unexpected property: ${key}`);
        }
    }
}

function validateComponentUpdate(data: any, errors: string[]) {
    if (!data.components || !Array.isArray(data.components)) {
        errors.push("ComponentUpdate must have a 'components' array.");
        return;
    }

    const componentIds = new Set<string>();
    for (const c of data.components) {
        if (c.id) {
            if (componentIds.has(c.id)) {
                errors.push(`Duplicate component ID found: ${c.id}`);
            }
            componentIds.add(c.id);
        }
    }

    for (const component of data.components) {
        validateComponent(component, componentIds, errors);
    }
}

function validateDataModelUpdate(data: any, errors: string[]) {
    if (data.contents === undefined) {
        errors.push("DataModelUpdate must have a 'contents' property.");
    }
}

function validateBeginRendering(data: any, errors: string[]) {
    if (!data.root) {
        errors.push("BeginRendering message must have a 'root' property.");
    }
}

function validateComponent(component: any, allIds: Set<string>, errors: string[]) {
    if (!component.id) {
        errors.push(`Component is missing an 'id'.`);
        return; // Can't validate further without an ID
    }
    if (!component.type) {
        errors.push(`Component '${component.id}' is missing a 'type'.`);
        return;
    }

    const checkRequired = (props: string[]) => {
        for (const prop of props) {
            if (component[prop] === undefined) {
                errors.push(`Component '${component.id}' of type '${component.type}' is missing required property '${prop}'.`);
            }
        }
    };

    const checkRefs = (ids: (string | undefined)[]) => {
        for (const id of ids) {
            if (id && !allIds.has(id)) {
                errors.push(`Component '${component.id}' references non-existent component ID '${id}'.`);
            }
        }
    };

    switch (component.type) {
        case 'Heading':
        case 'Text':
        case 'Image':
        case 'Video':
        case 'AudioPlayer':
        case 'TextField':
        case 'DateTimeInput':
        case 'MultipleChoice':
        case 'Slider':
            checkRequired(['value']);
            break;
        case 'CheckBox':
            checkRequired(['value', 'label']);
            break;
        case 'Row':
        case 'Column':
        case 'List':
            checkRequired(['children']);
            if (component.children) {
                const hasExplicit = !!component.children.explicitList;
                const hasTemplate = !!component.children.template;
                if ((hasExplicit && hasTemplate) || (!hasExplicit && !hasTemplate)) {
                    errors.push(`Component '${component.id}' must have either 'explicitList' or 'template' in children, but not both or neither.`);
                }
                if (hasExplicit) {
                    checkRefs(component.children.explicitList);
                }
                if (hasTemplate) {
                    checkRefs([component.children.template?.componentId]);
                }
            }
            break;
        case 'Card':
            checkRequired(['child']);
            checkRefs([component.child]);
            break;
        case 'Tabs':
            checkRequired(['tabItems']);
            if (component.tabItems && Array.isArray(component.tabItems)) {
                component.tabItems.forEach((tab: any) => {
                    if (!tab.title) {
                        errors.push(`Tab item in component '${component.id}' is missing a 'title'.`);
                    }
                    if (!tab.child) {
                        errors.push(`Tab item in component '${component.id}' is missing a 'child'.`);
                    }
                    checkRefs([tab.child])
                });
            }
            break;
        case 'Modal':
            checkRequired(['entryPointChild', 'contentChild']);
            checkRefs([component.entryPointChild, component.contentChild]);
            break;
        case 'Button':
            checkRequired(['label', 'action']);
            break;
        case 'Divider':
            break;
    }
}
