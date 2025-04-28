# Style System Documentation

## 1. Design Philosophy

- Atomic Design principles applied (atoms, molecules, organisms)
- Component-driven architecture
- Accessibility standards (WCAG 2.1 AA compliance)
- Mobile-first responsive design
- Consistent design language across components

## 2. SCSS Architecture

### Directory Structure

```
scss/
├── _base/
│   ├── _variables.scss
│   ├── _reset.scss
│   └── _typography.scss
├── _components/
│   ├── _button.scss
│   ├── _card.scss
│   ├── _form.scss
│   └── _icons.scss
├── _layout/
│   ├── _grid.scss
│   └── _navigation.scss
├── _themes/
│   ├── _light-theme.scss
│   └── _dark-theme.scss
└── style.scss
```

### Naming Conventions

- BEM methodology: `block__element--modifier`
- Global utilities: `u-` prefix
- Component classes: `c-` prefix
- Theme variables: `$theme-` prefix

### Global Variables

```scss
// _variables.scss
$color-primary: #2d8cff;
$color-secondary: #6c757d;
$font-family: "Inter", sans-serif;
$base-font-size: 16px;
$grid-gutter: 1.5rem;
```

### Mixins & Functions

```scss
// _mixins.scss
@mixin responsive-grid($columns: 12) {
  display: grid;
  grid-template-columns: repeat($columns, 1fr);
  gap: $grid-gutter;

  @media (max-width: 768px) {
    grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  }
}

@mixin transition($properties: all, $duration: 0.3s, $easing: ease-out) {
  transition: #{$properties} $duration $easing;
}
```

## 3. Component Documentation

### 3.1 Button Component

- **Purpose**: Primary user interaction element for triggering actions
- **SCSS Implementation**:
  ```scss
  .c-button {
    @include transition(color 0.3s);
    padding: 0.75rem 1.5rem;
    border: none;
    border-radius: 0.25rem;
    font-weight: 600;

    &--primary {
      background: $primary-color;
      color: white;

      &:hover {
        background: darken($primary-color, 10%);
      }
    }

    &--disabled {
      opacity: 0.5;
      cursor: not-allowed;
    }
  }
  ```
- **Usage**:

  ```jsx
  import styles from "../scss/components/button.module.scss";

  export default function Button() {
    return (
      <button
        className={styles["c-button c-button--primary"]}
        disabled={false}
        aria-label="Submit action"
      >
        Submit
      </button>
    );
  }
  ```

- **Accessibility**:
  - ARIA role="button"
  - Keyboard navigation support
  - High contrast mode enabled
- **Theme Variables**:
  - `$button-padding`: 0.75rem 1.5rem
  - `$button-border-radius`: 0.25rem
- **Responsive Behavior**:
  - Full width on mobile
  - Max width 200px on desktop
  - Spacing adjusts based on viewport width

### 3.2 Card Component

- **Purpose**: Modular content container with hover effects
- **SCSS Implementation**:
  ```scss
  .c-card {
    background: white;
    border-radius: 0.5rem;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
    padding: 1.5rem;
    transition: transform 0.2s ease-out;

    &:hover {
      transform: translateY(-2px);
    }

    &__header {
      margin-bottom: 1rem;
      font-size: 1.25rem;
      font-weight: 600;
    }

    &__content {
      line-height: 1.6;
    }
  }
  ```
- **Usage**:

  ```jsx
  import styles from '../scss/components/card.module.scss';

  export default function Card() {
    return (
      <div className={styles['c-card']}>
        <h3 className={styles['c-card__header']}>Featured Product</h3>
        <p className={styles['c-card__content']}>
          Loremspan className={styles['c-card__price']}>$99.99</span>
          Premium subscription plan with exclusive features
        </p>
      </div>
    );
  }
  ```

- **Accessibility**:
  - Semantic HTML structure
  - ARIA labels for interactive elements
  - Contrast ratio ≥ 4.5:1
- **Theme Variables**:
  - `$card-shadow`: 0 2px 8px rgba(0,0,0,0.1)
  - `$card-padding`: 1.5rem
- **Responsive Behavior**:
  - Breakpoint at 768px for grid layout
  - Max width 600px on desktop
  - Mobile-first card stacking

### 3.3 Form Component

- **Purpose**: Consistent form input styling and validation
- **SCSS Implementation**:
  ```scss
  .c-form {
    max-width: 600px;
    margin: 0 auto 2rem;

    &__group {
      margin-bottom: 1.5rem;
    }

    &__label {
      display: block;
      margin-bottom: 0.5rem;
      font-weight: 500;
    }

    &__input {
      width: 100%;
      padding: 0.75rem;
      border: 1px solid $color-secondary;
      border-radius: 0.25rem;

      &:focus {
        outline: 2px solid $primary-color;
        outline-offset: -2px;
      }
    }
  }
  ```
- **Usage**:

  ```jsx
  import styles from "../scss/components/form.module.scss";

  export default function Form() {
    return (
      <form className={styles["c-form"]}>
        <div className={styles["c-form__group"]}>
          <label className={styles["c-form__label"]} htmlFor="email">
            Email
          </label>
          <input
            type="email"
            className={styles["c-form__input"]}
            id="email"
            required
          />
        </div>
        <button type="submit" className={styles["c-button c-button--primary"]}>
          Submit
        </button>
      </form>
    );
  }
  ```

- **Accessibility**:
  - Required field indicators
  - Error states with ARIA live announcements
  - Keyboard navigation support
- **Theme Variables**:
  - `$form-border-color`: #e9ecef
  - `$form-focus-border`: 2px solid #2d8cff
- **Responsive Behavior**:
  - Input fields stack on mobile
  - Labels wrap automatically
  - Error messages display above fields

## 4. Theming System

### Default Theme Variables

```scss
// _themes/_light-theme.scss
$theme-primary: #2d8cff;
$theme-secondary: #6c757d;
$theme-background: #ffffff;
$theme-text: #212529;
```

### Theme Switching Implementation

```jsx
// ThemeProvider.js
import { createContext, useContext, useState, useEffect } from "react";

const ThemeContext = createContext();

export function ThemeProvider({ children }) {
  const [theme, setTheme] = useState("light");

  useEffect(() => {
    document.documentElement.classList.toggle("dark", theme === "dark");
  }, [theme]);

  return (
    <ThemeContext.Provider value={{ theme, setTheme }}>
      {children}
    </ThemeContext.Provider>
  );
}

export const useTheme = () => useContext(ThemeContext);
```

## 5. Global Styles

### Base Styles

```scss
// _base/_reset.scss
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

// _base/_typography.scss
body {
  font-family: $font-family;
  font-size: $base-font-size;
  line-height: 1.6;
  color: $theme-text;
}
```

## 6. Development Guidelines

- Component naming conventions
- SCSS import rules
- Version control strategies
- CI/CD pipeline integration

## 7. Component API Reference

### Button Component API

| Prop        | Type    | Default   | Description                      |
| ----------- | ------- | --------- | -------------------------------- |
| `variant`   | string  | 'primary' | 'primary', 'secondary', 'danger' |
| `size`      | string  | 'md'      | 'sm', 'md', 'lg'                 |
| `disabled`  | boolean | false     | Disables button interactions     |
| `fullWidth` | boolean | false     | Makes button 100% width          |

### Card Component API

| Prop          | Type    | Default | Description                         |
| ------------- | ------- | ------- | ----------------------------------- |
| `elevated`    | boolean | false   | Adds shadow and hover effects       |
| `interactive` | boolean | false   | Enables click-through functionality |
| `maxWidth`    | string  | '600px' | Maximum width for card content      |

## 8. Tooling Setup

### PostCSS Configuration

```js
// postcss.config.js
module.exports = {
  plugins: {
    "postcss-import": {},
    "postcss-nested": {},
    autoprefixer: {
      browsers: ["last 2 versions", "ie >= 11"],
    },
  },
};
```

## 9. Migration Guide

### From CSS to SCSS

1. Convert all CSS files to SCSS
2. Replace inline styles with class names
3. Migrate global variables to `_variables.scss`
4. Update component imports to use SCSS modules
5. Implement theme switching configuration

## 10. Component Library

### Available Components

| Component  | File Location              | Dependencies      |
| ---------- | -------------------------- | ----------------- |
| Button     | \_components/\_button.scss | Transition mixin  |
| Card       | \_components/\_card.scss   | Shadow utilities  |
| Form       | \_components/\_form.scss   | Validation mixins |
| Navigation | \_components/\_nav.scss    | Responsive grid   |
| Alert      | \_components/\_alert.scss  | Theme variables   |

## 11. Component Usage Examples

### 11.1 Button Variants

```jsx
// Primary Button
<button className={styles['c-button c-button--primary']}>Submit</button>

// Secondary Button
<button className={styles['c-button c-button--secondary']}>Cancel</button>

// Danger Button
<button className={styles['c-button c-button--danger']}>Delete</button>
```

### 11.2 Card with Interactive States

```jsx
import styles from '../scss/components/card.module.scss';

export default function ProductCard() {
  return (
    <div className={styles['c-card']}>
      <h3 className={styles['c-card__header']}>Product Name</h3>
      <p className={styles['c-card__content']}>
        Loremspan className={styles['c-card__price']}>$99.99</span>
        Premium subscription plan with exclusive features
      </p>
      <button className={`${styles['c-button']} ${styles['c-button--primary']}`}>
        Buy Now
      </button>
    </div>
  );
}
```

### 11.3 Form with Validation

```jsx
import styles from "../scss/components/form.module.scss";

export default function ContactForm() {
  return (
    <form className={styles["c-form"]}>
      <div className={styles["c-form__group"]}>
        <label className={styles["c-form__label"]} htmlFor="name">
          Name
        </label>
        <input
          type="text"
          className={styles["c-form__input"]}
          id="name"
          required
        />
      </div>
      <div className={styles["c-form__group"]}>
        <label className={styles["c-form__label"]} htmlFor="email">
          Email
        </label>
        <input
          type="email"
          className={styles["c-form__input"]}
          id="email"
          required
        />
      </div>
      <button type="submit" className={styles["c-button c-button--primary"]}>
        Submit
      </button>
    </form>
  );
}
```

## 12. Component Development Checklist

- [ ] Create SCSS component file in `_components/`
- [ ] Add JSDoc comments with @example tags
- [ ] Implement ARIA attributes
- [ ] Add responsive breakpoints
- [ ] Create Storybook story
- [ ] Add unit tests
- [ ] Update component API documentation
- [ ] Commit with semantic versioning
