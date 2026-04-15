# Web UI Inventory

This document lists the browser-facing UI surfaces in the repo and the main brand/logo assets that appear in the platform.

## 1. Core Web Apps

### OptScale main UI

The main platform UI lives under [`ngui`](../ngui).

Key entry files:

- [`ngui/ui/index.html`](../ngui/ui/index.html)
- [`ngui/ui/src/index.tsx`](../ngui/ui/src/index.tsx)
- [`ngui/ui/public/manifest.json`](../ngui/ui/public/manifest.json)
- [`ngui/ui/public/favicon.ico`](../ngui/ui/public/favicon.ico)
- [`ngui/ui/public/config.js`](../ngui/ui/public/config.js)
- [`ngui/server/server.ts`](../ngui/server/server.ts)

Main UI structure:

- `ngui/ui/src/components`
- `ngui/ui/src/containers`
- `ngui/ui/src/pages`
- `ngui/ui/src/layouts`
- `ngui/ui/src/assets`
- `ngui/ui/src/icons`
- `ngui/ui/src/hooks`
- `ngui/ui/src/contexts`
- `ngui/ui/src/reducers`
- `ngui/ui/src/services`
- `ngui/ui/src/translations`
- `ngui/ui/src/stories`

### Jira integration UI

The Jira integration UI lives under [`jira_ui`](../jira_ui).

Key entry files:

- [`jira_ui/ui/index.html`](../jira_ui/ui/index.html)
- [`jira_ui/ui/src/index.jsx`](../jira_ui/ui/src/index.jsx)
- [`jira_ui/ui/src/setupProxy.js`](../jira_ui/ui/src/setupProxy.js)
- [`jira_ui/server/index.js`](../jira_ui/server/index.js)

Main UI structure:

- `jira_ui/ui/src/components`
- `jira_ui/ui/src/containers`
- `jira_ui/ui/src/frames`
- `jira_ui/ui/src/hooks`
- `jira_ui/ui/src/utils`

## 2. Logo and Brand Assets

### Main OptScale logo set

These are the logo files used by the primary app UI:

- [`ngui/ui/src/assets/logo/logo.svg`](../ngui/ui/src/assets/logo/logo.svg)
- [`ngui/ui/src/assets/logo/logo_white.svg`](../ngui/ui/src/assets/logo/logo_white.svg)
- [`ngui/ui/src/assets/logo/logo_demo.svg`](../ngui/ui/src/assets/logo/logo_demo.svg)
- [`ngui/ui/src/assets/logo/logo_short_demo.svg`](../ngui/ui/src/assets/logo/logo_short_demo.svg)
- [`ngui/ui/src/assets/logo/logo_short_white.svg`](../ngui/ui/src/assets/logo/logo_short_white.svg)
- [`ngui/ui/src/assets/logo/logo_short_white_demo.svg`](../ngui/ui/src/assets/logo/logo_short_white_demo.svg)
- [`ngui/ui/src/assets/logo/logo_white_demo.svg`](../ngui/ui/src/assets/logo/logo_white_demo.svg)
- [`ngui/ui/src/assets/logo/logo_pdf.png`](../ngui/ui/src/assets/logo/logo_pdf.png)

### Main app icon / browser assets

- [`ngui/ui/public/favicon.ico`](../ngui/ui/public/favicon.ico)
- [`ngui/ui/public/manifest.json`](../ngui/ui/public/manifest.json)

### Cloud/provider logos shown in the UI

These are the exact asset files used by [`ngui/ui/src/hooks/useDataSources.ts`](../ngui/ui/src/hooks/useDataSources.ts):

- [`ngui/ui/src/assets/clouds/aws.svg`](../ngui/ui/src/assets/clouds/aws.svg)
- [`ngui/ui/src/assets/clouds/azure.svg`](../ngui/ui/src/assets/clouds/azure.svg)
- [`ngui/ui/src/assets/clouds/gcp.svg`](../ngui/ui/src/assets/clouds/gcp.svg)
- [`ngui/ui/src/assets/clouds/alibaba.svg`](../ngui/ui/src/assets/clouds/alibaba.svg)
- [`ngui/ui/src/assets/clouds/databricks.svg`](../ngui/ui/src/assets/clouds/databricks.svg)
- [`ngui/ui/src/assets/clouds/k8s.svg`](../ngui/ui/src/assets/clouds/k8s.svg)
- [`ngui/ui/src/assets/clouds/nebius.svg`](../ngui/ui/src/assets/clouds/nebius.svg)

### Integration logos shown in the UI

These are rendered in [`ngui/ui/src/components/IntegrationsGallery/IntegrationsGallery.tsx`](../ngui/ui/src/components/IntegrationsGallery/IntegrationsGallery.tsx):

- [`ngui/ui/src/assets/integrations/slack.svg`](../ngui/ui/src/assets/integrations/slack.svg)
- [`ngui/ui/src/assets/integrations/jenkins.svg`](../ngui/ui/src/assets/integrations/jenkins.svg)
- [`ngui/ui/src/assets/integrations/jira.svg`](../ngui/ui/src/assets/integrations/jira.svg)
- [`ngui/ui/src/assets/integrations/gitlab.svg`](../ngui/ui/src/assets/integrations/gitlab.svg)
- [`ngui/ui/src/assets/integrations/github.svg`](../ngui/ui/src/assets/integrations/github.svg)
- [`ngui/ui/src/assets/integrations/terraform.svg`](../ngui/ui/src/assets/integrations/terraform.svg)
- [`ngui/ui/src/assets/integrations/databricks.svg`](../ngui/ui/src/assets/integrations/databricks.svg)
- [`ngui/ui/src/assets/integrations/pytorch.svg`](../ngui/ui/src/assets/integrations/pytorch.svg)
- [`ngui/ui/src/assets/integrations/kubeflow.svg`](../ngui/ui/src/assets/integrations/kubeflow.svg)
- [`ngui/ui/src/assets/integrations/spark.svg`](../ngui/ui/src/assets/integrations/spark.svg)
- [`ngui/ui/src/assets/integrations/tensorflow.svg`](../ngui/ui/src/assets/integrations/tensorflow.svg)

### Customer logos used on marketing/welcome screens

- [`ngui/ui/src/assets/customers/airbus.svg`](../ngui/ui/src/assets/customers/airbus.svg)
- [`ngui/ui/src/assets/customers/pwc.svg`](../ngui/ui/src/assets/customers/pwc.svg)
- [`ngui/ui/src/assets/customers/dhl.svg`](../ngui/ui/src/assets/customers/dhl.svg)
- [`ngui/ui/src/assets/customers/yves-rocher.svg`](../ngui/ui/src/assets/customers/yves-rocher.svg)
- [`ngui/ui/src/assets/customers/t-systems.svg`](../ngui/ui/src/assets/customers/t-systems.svg)
- [`ngui/ui/src/assets/customers/bentley.svg`](../ngui/ui/src/assets/customers/bentley.svg)
- [`ngui/ui/src/assets/customers/nokia.svg`](../ngui/ui/src/assets/customers/nokia.svg)

### Jira UI logo asset

- [`jira_ui/ui/public/icons/logo.png`](../jira_ui/ui/public/icons/logo.png)

## 3. Logo/Icon Components

### Main app logo component

- [`ngui/ui/src/components/Logo/Logo.tsx`](../ngui/ui/src/components/Logo/Logo.tsx)
- [`ngui/ui/src/components/Logo/index.ts`](../ngui/ui/src/components/Logo/index.ts)
- [`ngui/ui/src/components/Logo/Logo.test.tsx`](../ngui/ui/src/components/Logo/Logo.test.tsx)

### Provider/logo icon components

These are the React icon wrappers used across the main UI:

- [`ngui/ui/src/icons/AwsLogoIcon/AwsLogoIcon.tsx`](../ngui/ui/src/icons/AwsLogoIcon/AwsLogoIcon.tsx)
- [`ngui/ui/src/icons/AzureLogoIcon/AzureLogoIcon.tsx`](../ngui/ui/src/icons/AzureLogoIcon/AzureLogoIcon.tsx)
- [`ngui/ui/src/icons/GcpLogoIcon/GcpLogoIcon.tsx`](../ngui/ui/src/icons/GcpLogoIcon/GcpLogoIcon.tsx)
- [`ngui/ui/src/icons/AlibabaLogoIcon/AlibabaLogoIcon.tsx`](../ngui/ui/src/icons/AlibabaLogoIcon/AlibabaLogoIcon.tsx)
- [`ngui/ui/src/icons/DatabricksLogoIcon/DatabricksLogoIcon.tsx`](../ngui/ui/src/icons/DatabricksLogoIcon/DatabricksLogoIcon.tsx)
- [`ngui/ui/src/icons/K8sLogoIcon/K8sLogoIcon.tsx`](../ngui/ui/src/icons/K8sLogoIcon/K8sLogoIcon.tsx)
- [`ngui/ui/src/icons/NebiusLogoIcon/NebiusLogoIcon.tsx`](../ngui/ui/src/icons/NebiusLogoIcon/NebiusLogoIcon.tsx)
- [`ngui/ui/src/icons/JiraIcon/JiraIcon.tsx`](../ngui/ui/src/icons/JiraIcon/JiraIcon.tsx)
- [`ngui/ui/src/icons/SlackIcon/SlackIcon.tsx`](../ngui/ui/src/icons/SlackIcon/SlackIcon.tsx)
- [`ngui/ui/src/icons/GitLabIcon/GitLabIcon.tsx`](../ngui/ui/src/icons/GitLabIcon/GitLabIcon.tsx)
- [`ngui/ui/src/icons/GoogleIcon/GoogleIcon.tsx`](../ngui/ui/src/icons/GoogleIcon/GoogleIcon.tsx)
- [`ngui/ui/src/icons/GoogleCalendarIcon/GoogleCalendarIcon.tsx`](../ngui/ui/src/icons/GoogleCalendarIcon/GoogleCalendarIcon.tsx)
- [`ngui/ui/src/icons/MicrosoftIcon/MicrosoftIcon.tsx`](../ngui/ui/src/icons/MicrosoftIcon/MicrosoftIcon.tsx)

## 4. Files That Bind Logos to Screens

These files decide where the logos appear in the UI:

- [`ngui/ui/src/hooks/useDataSources.ts`](../ngui/ui/src/hooks/useDataSources.ts)
- [`ngui/ui/src/components/IntegrationsGallery/IntegrationsGallery.tsx`](../ngui/ui/src/components/IntegrationsGallery/IntegrationsGallery.tsx)
- [`ngui/ui/src/components/ConnectJira/ConnectJira.tsx`](../ngui/ui/src/components/ConnectJira/ConnectJira.tsx)
- [`ngui/ui/src/components/LiveDemo/LiveDemo.tsx`](../ngui/ui/src/components/LiveDemo/LiveDemo.tsx)
- [`ngui/ui/src/layouts/BaseLayout/BaseLayout.tsx`](../ngui/ui/src/layouts/BaseLayout/BaseLayout.tsx)
- [`ngui/ui/src/layouts/BaseLayout/BaseLayout.styles.ts`](../ngui/ui/src/layouts/BaseLayout/BaseLayout.styles.ts)

## 5. Jira UI Surface

The Jira integration app is much smaller, and its UI is concentrated in:

- `jira_ui/ui/src/components`
- `jira_ui/ui/src/containers`
- `jira_ui/ui/src/frames`
- `jira_ui/ui/src/hooks`
- `jira_ui/ui/src/utils`

The primary visible branding asset is [`jira_ui/ui/public/icons/logo.png`](../jira_ui/ui/public/icons/logo.png).

## 6. Notes

- The `ngui` app is the main FinOps platform UI.
- The `jira_ui` app is a separate integration UI for Jira.
- The `ngui` asset tree is the main source of logos and visual branding in the platform.
- If you want a literal file-by-file dump of every React component under `ngui/ui/src` or `jira_ui/ui/src`, that can be generated as a second pass.
