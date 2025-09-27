// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

export interface ValidationResult {
  success: boolean;
  error?: string;
}

export class ComponentUpdateSchemaMatcher {
  constructor(
    public componentName: string,
    public propertyName?: string,
    public matchText?: string
  ) {}

  validate(schema: any): ValidationResult {
    if (!schema.components || !Array.isArray(schema.components)) {
      return {
        success: false,
        error: 'ComponentUpdate message must have a "components" array.',
      };
    }

    for (const component of schema.components) {
      if (component.componentProperties?.[this.componentName]) {
        const properties = component.componentProperties[this.componentName];
        if (!this.propertyName) {
          // Component found, no property check needed.
          return { success: true };
        }

        if (properties[this.propertyName]) {
          if (!this.matchText) {
            // Property found, no text match needed.
            return { success: true };
          }

          if (this.findText(properties[this.propertyName], this.matchText)) {
            return { success: true };
          }
        }
      }
    }

    let error = `Failed to find component '${this.componentName}'`;
    if (this.propertyName) {
      error += ` with property '${this.propertyName}'`;
    }
    if (this.matchText) {
      error += ` containing text '${this.matchText}'`;
    }
    error += '.';
    return { success: false, error };
  }

  private findText(obj: any, text: string): boolean {
    if (typeof obj === 'string') {
      return obj.toLowerCase().includes(text.toLowerCase());
    }
    if (typeof obj === 'object' && obj !== null) {
      for (const key in obj) {
        if (this.findText(obj[key], text)) {
          return true;
        }
      }
    }
    return false;
  }
}
