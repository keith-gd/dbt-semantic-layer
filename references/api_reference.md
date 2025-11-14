# Dbt-Semantic-Layer - Api Reference

**Pages:** 12

---

## Zapier looks for the `output` dictionary for use in subsequent steps

**URL:** llms-txt#zapier-looks-for-the-`output`-dictionary-for-use-in-subsequent-steps

output = {'step_summary_post': step_summary_post, 'send_error_thread': send_error_thread, 'threaded_errors_post': threaded_errors_post}

store = StoreClient('abc123') #replace with your UUID secret
store.set('DBT_CLOUD_SERVICE_TOKEN', 'abc123') #replace with your <Constant name="cloud" /> API token
`
import re

**Examples:**

Example 1 (unknown):
```unknown
#### Add Slack actions in Zapier[​](#add-slack-actions-in-zapier "Direct link to Add Slack actions in Zapier")

Select **Slack** as the App, and **Send Channel Message** as the Action.

In the **Action** section, choose which **Channel** to post to. Set the **Message Text** field to **2. Step Summary Post** from the Run Python in Code by Zapier output.

Configure the other options as you prefer (for example, **Bot Name** and **Bot Icon**).

![Screenshot of the Zapier UI, showing the mappings of prior steps to a Slack message](/assets/images/parent-slack-config-39e85487efcfb04136c351992ed08cb9.png)

Add another step, **Filter**. In the **Filter setup and testing** section, set the **Field** to **2. Send Error Thread** and the **condition** to **(Boolean) Is true**. This prevents the Zap from failing if the job succeeded and you try to send an empty Slack message in the next step.

![Screenshot of the Zapier UI, showing the correctly configured Filter step](/assets/images/filter-config-5a7f7eca78c49d24fd5b8674f23337e3.png)

Add another **Send Channel Message in Slack** action. In the **Action** section, choose the same channel as last time, but set the **Message Text** to **2. Threaded Errors Post** from the same Run Python step. Set the **Thread** value to **3. Message Ts**, which is the timestamp of the post created by the first Slack action. This tells Zapier to add this post as a threaded reply to the main message, which prevents the full (potentially long) output from cluttering your channel.

![Screenshot of the Zapier UI, showing the mappings of prior steps to a Slack message](/assets/images/thread-slack-config-9ebe2df87964d97e82c18d80d9ff9ac2.png)

#### Test and deploy[​](#test-and-deploy "Direct link to Test and deploy")

When you're done testing your Zap, make sure that your `run_id` and `account_id` are no longer hardcoded in the Code step, then publish your Zap.

#### Alternately, use a dbt app Slack message to trigger Zapier[​](#alternately-use-a-dbt-app-slack-message-to-trigger-zapier "Direct link to Alternately, use a dbt app Slack message to trigger Zapier")

Instead of using a webhook as your trigger, you can keep the existing dbt app installed in your Slack workspace and use its messages being posted to your channel as the trigger. In this case, you can skip validating the webhook and only need to load the context from the thread.

##### 1. Create a new Zap in Zapier[​](#1-create-a-new-zap-in-zapier "Direct link to 1. Create a new Zap in Zapier")

Use **Slack** as the initiating app, and **New Message Posted to Channel** as the Trigger. In the **Trigger** section, select the channel where your Slack alerts are being posted, and set **Trigger for Bot Messages?** to **Yes**.

![Screenshot of the Zapier UI, showing the correctly configured Message trigger step](/assets/images/message-trigger-config-432c82983008423e7914d0c59eab38cd.png)

Test your Zap to find an example record. You might need to load additional samples until you get one that relates to a failed job, depending on whether you post all job events to Slack or not.

##### 2. Add a Filter step[​](#2-add-a-filter-step "Direct link to 2. Add a Filter step")

Add a **Filter** step with the following conditions:

* **1. Text contains failed on Job**
* **1. User Is Bot Is true**
* **1. User Name Exactly matches dbt**

![Screenshot of the Zapier UI, showing the correctly configured Filter step](/assets/images/message-trigger-filter-57c4f8c530e21a72704481619b040a51.png)

##### 3. Extract the run ID[​](#3-extract-the-run-id "Direct link to 3. Extract the run ID")

Add a **Format** step with the **Event** of **Text**, and the Action **Extract Number**. For the **Input**, select **1. Text**.

![Screenshot of the Zapier UI, showing the Transform step configured to extract a number from the Slack message\&#39;s Text property](/assets/images/extract-number-e9674c26f01614ccfd93b7fdefaab3ed.png)

Test your step and validate that the run ID has been correctly extracted.

##### 4. Add a Delay[​](#4-add-a-delay "Direct link to 4. Add a Delay")

Sometimes dbt posts the message about the run failing before the run's artifacts are available through the API. For this reason, it's recommended to add a brief delay to increase the likelihood that the data is available. On certain plans, Zapier will automatically retry a job that fails from to a 404 error, but its standdown period is longer than is normally necessary so the context will be missing from your thread for longer.

A one-minute delay is generally sufficient.

##### 5. Store secrets[​](#5-store-secrets "Direct link to 5. Store secrets")

In the next step, you will need either a dbt [personal access token](https://docs.getdbt.com/docs/dbt-cloud-apis/user-tokens.md) or [service account token](https://docs.getdbt.com/docs/dbt-cloud-apis/service-tokens.md).

Zapier allows you to [store secrets](https://help.zapier.com/hc/en-us/articles/8496293271053-Save-and-retrieve-data-from-Zaps). This prevents your keys from being displayed as plaintext in the Zap code. You can access them with the [StoreClient utility](https://help.zapier.com/hc/en-us/articles/8496293969549-Store-data-from-code-steps-with-StoreClient).

This guide assumes the name for the secret key is `DBT_CLOUD_SERVICE_TOKEN`. If you're using a different name, make sure you update all references to it in the sample code.

This guide uses a short-lived code action to store the secrets, but you can also use a tool like Postman to interact with the [REST API](https://store.zapier.com/) or create a separate Zap and call the [Set Value Action](https://help.zapier.com/hc/en-us/articles/8496293271053-Save-and-retrieve-data-from-Zaps#3-set-a-value-in-your-store-0-3).

###### a. Create a Storage by Zapier connection[​](#a-create-a-storage-by-zapier-connection "Direct link to a. Create a Storage by Zapier connection")

If you haven't already got one, go to <https://zapier.com/app/connections/storage> and create a new connection. Remember the UUID secret you generate for later.

###### b. Add a temporary code step[​](#b-add-a-temporary-code-step "Direct link to b. Add a temporary code step")

Choose **Run Python** as the Event. Run the following code:
```

Example 2 (unknown):
```unknown
Test the step. You can delete this Action when the test succeeds. The key will remain stored as long as it is accessed at least once every three months.

##### 6. Add a Code action[​](#6-add-a-code-action "Direct link to 6. Add a Code action")

Select **Code by Zapier** as the App, and **Run Python** as the Event.

This step is very similar to the one described in the main example, but you can skip a lot of the initial validation work.

In the **Action** section, add two items to **Input Data**: `run_id` and `account_id`. Map those to the `3. Output` property and your hardcoded dbt Account ID, respectively.

![Screenshot of the Zapier UI, showing the mappings of raw\_body and auth\_header](/assets/images/code-example-alternate-bbb2b5028df008f1b6832e8453215ff4.png)

In the **Code** field, paste the following code, replacing `YOUR_SECRET_HERE` with the secret you created when setting up the Storage by Zapier integration. Remember that this is not your dbt secret.

This example code extracts the run logs for the completed job from the Admin API, and then builds a message displaying any error messages extracted from the end-of-invocation logs created by dbt Core (which will be posted in a thread).
```

---

## Get the latest run metadata for all models

**URL:** llms-txt#get-the-latest-run-metadata-for-all-models

models_latest_metadata = query_discovery_api(auth_token, query_one, variables_query_one)['environment']

---

## dbt Developer Hub

**URL:** llms-txt#dbt-developer-hub

**Contents:**
- API Reference
  - About the Discovery API schema
  - About the Discovery API StarterEnterpriseEnterprise +
  - About the Discovery API [Starter](https://www.getdbt.com/pricing "Go to https://www.getdbt.com/pricing")[Enterprise](https://www.getdbt.com/pricing "Go to https://www.getdbt.com/pricing")[Enterprise +](https://www.getdbt.com/pricing "Go to https://www.getdbt.com/pricing")
  - Account-scoped personal access tokens
  - APIs overview StarterEnterpriseEnterprise +
  - APIs overview [Starter](https://www.getdbt.com/pricing "Go to https://www.getdbt.com/pricing")[Enterprise](https://www.getdbt.com/pricing "Go to https://www.getdbt.com/pricing")[Enterprise +](https://www.getdbt.com/pricing "Go to https://www.getdbt.com/pricing")
  - Applied object schema
  - Fetching data...
  - Authentication tokens

> End user documentation, guides and technical reference for dbt

### About the Discovery API schema

With the Discovery API, you can query the metadata in dbt to learn more about your dbt deployments and the data they generate. You can analyze the data to make improvements. If you are new to the API, refer to [About the Discovery API](https://docs.getdbt.com/docs/dbt-cloud-apis/discovery-api.md) for an introduction. You might also find the [use cases and examples](https://docs.getdbt.com/docs/dbt-cloud-apis/discovery-use-cases-and-examples.md) helpful.

The Discovery API *schema* provides all the pieces necessary to query and interact with the Discovery API. The most common queries use the `environment` endpoint:

[![](/img/icons/dbt-bit.svg)](https://docs.getdbt.com/docs/dbt-cloud-apis/discovery-schema-environment.md)

###### [Environment schema](https://docs.getdbt.com/docs/dbt-cloud-apis/discovery-schema-environment.md)

[Query and compare a model’s definition (intended) and its applied (actual) state.](https://docs.getdbt.com/docs/dbt-cloud-apis/discovery-schema-environment.md)

[![](/img/icons/dbt-bit.svg)](https://docs.getdbt.com/docs/dbt-cloud-apis/discovery-schema-environment-applied.md)

###### [Applied schema](https://docs.getdbt.com/docs/dbt-cloud-apis/discovery-schema-environment-applied.md)

[Query the actual state of objects and metadata in the warehouse after a \`dbt run\` or \`dbt build\`.](https://docs.getdbt.com/docs/dbt-cloud-apis/discovery-schema-environment-applied.md)

[![](/img/icons/dbt-bit.svg)](https://docs.getdbt.com/docs/dbt-cloud-apis/discovery-schema-environment-definition.md)

###### [Definition schema](https://docs.getdbt.com/docs/dbt-cloud-apis/discovery-schema-environment-definition.md)

[Query intended state in project code and configuration defined in your dbt project.](https://docs.getdbt.com/docs/dbt-cloud-apis/discovery-schema-environment-definition.md)

[![](/img/icons/dbt-bit.svg)](https://docs.getdbt.com/docs/dbt-cloud-apis/discovery-schema-environment-applied-modelHistoricalRuns.md)

###### [Model Historical Runs schema](https://docs.getdbt.com/docs/dbt-cloud-apis/discovery-schema-environment-applied-modelHistoricalRuns.md)

[Query information about a model's run history.](https://docs.getdbt.com/docs/dbt-cloud-apis/discovery-schema-environment-applied-modelHistoricalRuns.md)

#### Was this page helpful?

[Privacy policy](https://www.getdbt.com/cloud/privacy-policy)[Create a GitHub issue](https://github.com/dbt-labs/docs.getdbt.com/issues)

This site is protected by reCAPTCHA and the Google [Privacy Policy](https://policies.google.com/privacy) and [Terms of Service](https://policies.google.com/terms) apply.

### About the Discovery API StarterEnterpriseEnterprise +

### About the Discovery API [Starter](https://www.getdbt.com/pricing "Go to https://www.getdbt.com/pricing")[Enterprise](https://www.getdbt.com/pricing "Go to https://www.getdbt.com/pricing")[Enterprise +](https://www.getdbt.com/pricing "Go to https://www.getdbt.com/pricing")

Every time dbt runs a project, it generates and stores information about the project. The metadata includes details about your project’s models, sources, and other nodes along with their execution results. With the dbt Discovery API, you can query this comprehensive information to gain a better understanding of your DAG and the data it produces.

By leveraging the metadata in dbt, you can create systems for data monitoring and alerting, lineage exploration, and automated reporting. This can help you improve data discovery, data quality, and pipeline operations within your organization.

You can access the Discovery API through [ad hoc queries](https://docs.getdbt.com/docs/dbt-cloud-apis/discovery-querying.md), custom applications, a wide range of [partner ecosystem integrations](https://www.getdbt.com/product/integrations/) (like BI/analytics, catalog and governance, and quality and observability), and by using dbt features like [model timing](https://docs.getdbt.com/docs/deploy/run-visibility.md#model-timing) and [data health tiles](https://docs.getdbt.com/docs/explore/data-tile.md).

[![A rich ecosystem for integration ](/img/docs/dbt-cloud/discovery-api/discovery-api-figure.png?v=2 "A rich ecosystem for integration ")](#)A rich ecosystem for integration

You can query the dbt metadata:

* At the [environment](https://docs.getdbt.com/docs/environments-in-dbt.md) level for both the latest state (use the `environment` endpoint) and historical run results (use `modelHistoricalRuns`) of a dbt project in production.
* At the job level for results on a specific dbt job run for a given resource type, like `models` or `test`.

#### Prerequisites[​](#prerequisites "Direct link to Prerequisites")

* dbt [multi-tenant](https://docs.getdbt.com/docs/cloud/about-cloud/tenancy.md#multi-tenant) or [single tenant](https://docs.getdbt.com/docs/cloud/about-cloud/tenancy.md#single-tenant) account
* You must be on an [Enterprise or Enterprise+ plan](https://www.getdbt.com/pricing/)
* Your projects must be on a dbt [release tracks](https://docs.getdbt.com/docs/dbt-versions/cloud-release-tracks.md) or dbt version 1.0 or later. Refer to [Upgrade dbt version in Cloud](https://docs.getdbt.com/docs/dbt-versions/upgrade-dbt-version-in-cloud.md) to upgrade.

#### What you can use the Discovery API for[​](#what-you-can-use-the-discovery-api-for "Direct link to What you can use the Discovery API for")

Click the following tabs to learn more about the API's use cases, the analysis you can do, and the results you can achieve by integrating with it.

To use the API directly or integrate your tool with it, refer to [Uses case and examples](https://docs.getdbt.com/docs/dbt-cloud-apis/discovery-use-cases-and-examples.md) for detailed information.

* Performance
* Quality
* Discovery
* Governance
* Development

Use the API to look at historical information like model build time to determine the health of your dbt projects. Finding inefficiencies in orchestration configurations can help decrease infrastructure costs and improve timeliness. To learn more about how to do this, refer to [Performance](https://docs.getdbt.com/docs/dbt-cloud-apis/discovery-use-cases-and-examples.md#performance).

You can use, for example, the [model timing](https://docs.getdbt.com/docs/deploy/run-visibility.md#model-timing) tab to help identify and optimize bottlenecks in model builds:

[![Model timing visualization in dbt](/img/docs/dbt-cloud/discovery-api/model-timing.png?v=2 "Model timing visualization in dbt")](#)Model timing visualization in dbt

Use the API to determine if the data is accurate and up-to-date by monitoring test failures, source freshness, and run status. Accurate and reliable information is valuable for analytics, decisions, and monitoring to help prevent your organization from making bad decisions. To learn more about this, refer to [Quality](https://docs.getdbt.com/docs/dbt-cloud-apis/discovery-use-cases-and-examples.md#quality).

When used with [webhooks](https://docs.getdbt.com/docs/deploy/webhooks.md), it can also help with detecting, investigating, and alerting issues.

Use the API to find and understand dbt assets in integrated tools using information like model and metric definitions, and column information. For more details, refer to [Discovery](https://docs.getdbt.com/docs/dbt-cloud-apis/discovery-use-cases-and-examples.md#discovery).

Data producers must manage and organize data for stakeholders, while data consumers need to quickly and confidently analyze data on a large scale to make informed decisions that improve business outcomes and reduce organizational overhead. The API is useful for discovery data experiences in catalogs, analytics, apps, and machine learning (ML) tools. It can help you understand the origin and meaning of datasets for your analysis.

[![Data lineage produced by dbt](/img/docs/collaborate/dbt-explorer/example-model-details.png?v=2 "Data lineage produced by dbt")](#)Data lineage produced by dbt

Use the API to review who developed the models and who uses them to help establish standard practices for better governance. For more details, refer to [Governance](https://docs.getdbt.com/docs/dbt-cloud-apis/discovery-use-cases-and-examples.md#governance).

Use the API to review dataset changes and uses by examining exposures, lineage, and dependencies. From the investigation, you can learn how to define and build more effective dbt projects. For more details, refer to [Development](https://docs.getdbt.com/docs/dbt-cloud-apis/discovery-use-cases-and-examples.md#development).

[![Use exposures to embed data health tiles in your dashboards to distill trust signals for data consumers.](/img/docs/collaborate/dbt-explorer/data-tile-pass.jpg?v=2 "Use exposures to embed data health tiles in your dashboards to distill trust signals for data consumers.")](#)Use exposures to embed data health tiles in your dashboards to distill trust signals for data consumers.

#### Types of project state[​](#types-of-project-state "Direct link to Types of project state")

You can query these two types of [project state](https://docs.getdbt.com/docs/dbt-cloud-apis/project-state.md) at the environment level:

* **Definition** — The logical state of a dbt project’s [resources](https://docs.getdbt.com/docs/build/projects.md) that update when the project is changed.
* **Applied** — The output of successful dbt DAG execution that creates or describes the state of the database (for example: `dbt run`, `dbt test`, source freshness, and so on)

These states allow you to easily examine the difference between a model’s definition and its applied state so you can get answers to questions like, did the model run? or did the run fail? Applied models exist as a table/view in the data platform given their most recent successful run.

#### Related docs[​](#related-docs "Direct link to Related docs")

* [Use cases and examples for the Discovery API](https://docs.getdbt.com/docs/dbt-cloud-apis/discovery-use-cases-and-examples.md)
* [Query the Discovery API](https://docs.getdbt.com/docs/dbt-cloud-apis/discovery-querying.md)
* [Schema](https://docs.getdbt.com/docs/dbt-cloud-apis/discovery-schema-job.md)

#### Was this page helpful?

[Privacy policy](https://www.getdbt.com/cloud/privacy-policy)[Create a GitHub issue](https://github.com/dbt-labs/docs.getdbt.com/issues)

This site is protected by reCAPTCHA and the Google [Privacy Policy](https://policies.google.com/privacy) and [Terms of Service](https://policies.google.com/terms) apply.

### Account-scoped personal access tokens

User API tokens have been deprecated and will no longer work. [Migrate](#migrate-deprecated-user-api-keys-to-personal-access-tokens) to personal access tokens to resume services.

Each dbt user with a [Developer license](https://docs.getdbt.com/docs/cloud/manage-access/seats-and-users.md) can create a new personal access token (PAT) to access the dbt API and dbt CLI. This token can execute queries against the dbt API on the user's behalf. To access dbt APIs and resources on behalf of the *account*, we recommend using service tokens instead. Learn more about [which token type you should use](https://docs.getdbt.com/docs/dbt-cloud-apis/authentication.md#which-token-type-should-you-use) to understand the token differences.

PATs inherit the permissions of the user that created them. For example, if a developer-licensed user with Project Admin role access to specific projects creates a PAT, the token will get the Project Admin role with access to the same projects as the user. These tokens are also account-specific, so if a user has access to more than one dbt account with the same email address, they need to create a unique PAT for each one of these accounts.

#### Create a personal access token[​](#create-a-personal-access-token "Direct link to Create a personal access token")

Creating an account-scoped PAT requires only a few steps.

1. Navigate to your **Account Settings**, expand **API tokens** and click **Personal tokens**.

2. Click **Create personal access token**.

3. Give the token a descriptive name and click **Save**.

4. Copy the token before closing the window. *It will not be available after, and you will have to create a new token if you lose it.*

To maintain best security practices, it's recommended that you regularly rotate your PATs. To do so, create a new token and delete the old one once it's in place.

#### Delete a personal access token[​](#delete-a-personal-access-token "Direct link to Delete a personal access token")

To permanently delete a PAT:

1. Navigate to your **Account Settings**, expand **API tokens** and click **Personal tokens**.
2. Find the token you want to delete and click "X" to the right of the token description fields.
3. **Confirm delete** and the token will no longer be valid.

#### Migrate deprecated user API keys to personal access tokens[​](#migrate-deprecated-user-api-keys-to-personal-access-tokens "Direct link to Migrate deprecated user API keys to personal access tokens")

The migration to PATs is critical if you are using user API keys today. The current API key is located under **Personal Settings → API Key**.

There are a few things to understand if you are using a user API key today:

* PATs are more secure.
  <!-- -->
  * To promote the least privilege and high-security assurance for your dbt accounts, we highly recommend moving to the new account-scoped PATs.

* You must create and use unique tokens in each one of your dbt accounts that share the same email address.

* For example, if <paul.atreides@example.com> belongs to two dbt accounts: Spice Harvesting Account and Guild Navigator Account. Before this release, the same API key was used to access both of these accounts.
  * After this release, Paul has to individually go into these accounts and create a unique PAT for each account he wants to access the API for. These PATs are account-specific and not user specific.

* Cross-Account API endpoints will change in behavior when using PATs.

* These are namely /v2/accounts and /v3/accounts. Since all PATs are now account specific, getting all accounts associated with a username cannot work. /v3/accounts will only return account metadata that’s relevant to the PAT that’s being used.
  * User account metadata will only contain information about the specific account under which the request is being made.
  * Any other accounts that belong to that user account will need to be requested through the PAT that belongs to that account.

If you’re using any undocumented and unsupported API endpoints, please note that these can be deprecated without any notice. If you are using any undocumented endpoints and have use-cases that are not satisfied by the current API, please reach out to <support@getdbt.com>.

##### Using the personal access tokens[​](#using-the-personal-access-tokens "Direct link to Using the personal access tokens")

Are you using a user API key today to access dbt APIs in any of your workflows? If not, you don’t have any action to take. If you are using a user API key, please follow the instructions below.

1. Make a list of all the places where you’re making a call to the dbt API using the dbt user API key.

2. Create a new PAT under **Account Settings → API Tokens → Personal Tokens.** For instructions, see [Create a personal access token](#create-a-personal-access-token).

3. Replace the API key in your APIs with the PAT you created. You can use a PAT wherever you previously used an API key.

To replace the API key with a PAT, include the PAT in the Authorization header of your API requests. For example: `Authorization: Bearer <your-token>`.

Make sure to replace `<your-token>` with the new PAT you created.

The option to rotate API keys is used for existing API keys, not for replacing them with PATs. You do not need to replace your API key with a PAT in the dbt UI.

4. Ensure that you’re using a PAT only where it's needed. For flows that require a service account, please use a service token.

#### Was this page helpful?

[Privacy policy](https://www.getdbt.com/cloud/privacy-policy)[Create a GitHub issue](https://github.com/dbt-labs/docs.getdbt.com/issues)

This site is protected by reCAPTCHA and the Google [Privacy Policy](https://policies.google.com/privacy) and [Terms of Service](https://policies.google.com/terms) apply.

### APIs overview StarterEnterpriseEnterprise +

### APIs overview [Starter](https://www.getdbt.com/pricing "Go to https://www.getdbt.com/pricing")[Enterprise](https://www.getdbt.com/pricing "Go to https://www.getdbt.com/pricing")[Enterprise +](https://www.getdbt.com/pricing "Go to https://www.getdbt.com/pricing")

Accounts on the Enterprise and Enterprise+ plans can query the dbt APIs.

dbt provides the following APIs:

* The [dbt Administrative API](https://docs.getdbt.com/docs/dbt-cloud-apis/admin-cloud-api.md) can be used to administrate a dbt account. It can be called manually or with [the dbt Terraform provider](https://registry.terraform.io/providers/dbt-labs/dbtcloud/latest).
* The [dbt Discovery API](https://docs.getdbt.com/docs/dbt-cloud-apis/discovery-api.md) can be used to fetch metadata related to the state and health of your dbt project.
* The [Semantic Layer APIs](https://docs.getdbt.com/docs/dbt-cloud-apis/sl-api-overview.md) provides multiple API options which allow you to query your metrics defined in the Semantic Layer.

If you want to learn more about webhooks, refer to [Webhooks for your jobs](https://docs.getdbt.com/docs/deploy/webhooks.md).

#### How to Access the APIs[​](#how-to-access-the-apis "Direct link to How to Access the APIs")

dbt supports two types of API Tokens: [personal access tokens](https://docs.getdbt.com/docs/dbt-cloud-apis/user-tokens.md) and [service account tokens](https://docs.getdbt.com/docs/dbt-cloud-apis/service-tokens.md). Requests to the dbt APIs can be authorized using these tokens.

#### Was this page helpful?

[Privacy policy](https://www.getdbt.com/cloud/privacy-policy)[Create a GitHub issue](https://github.com/dbt-labs/docs.getdbt.com/issues)

This site is protected by reCAPTCHA and the Google [Privacy Policy](https://policies.google.com/privacy) and [Terms of Service](https://policies.google.com/terms) apply.

### Applied object schema

The applied object allows you to query information about a particular model based on `environmentId`.

The [Example queries](#example-queries) illustrate a few fields you can query with this `environment` object. Refer to [Fields](#fields) to view the entire schema, which provides all possible fields you can query.

##### Example queries[​](#example-queries "Direct link to Example queries")

You can use your production environment's `id`:

##### Fields[​](#fields "Direct link to Fields")

When querying the `applied` field of `environment`, you can use the following fields.

#### Was this page helpful?

[Privacy policy](https://www.getdbt.com/cloud/privacy-policy)[Create a GitHub issue](https://github.com/dbt-labs/docs.getdbt.com/issues)

This site is protected by reCAPTCHA and the Google [Privacy Policy](https://policies.google.com/privacy) and [Terms of Service](https://policies.google.com/terms) apply.

### Authentication tokens

[![](/img/icons/dbt-bit.svg)](https://docs.getdbt.com/docs/dbt-cloud-apis/user-tokens.md)

###### [Personal access tokens](https://docs.getdbt.com/docs/dbt-cloud-apis/user-tokens.md)

[Learn about user tokens and how to use them to execute queries against the dbt API.](https://docs.getdbt.com/docs/dbt-cloud-apis/user-tokens.md)

[![](/img/icons/dbt-bit.svg)](https://docs.getdbt.com/docs/dbt-cloud-apis/service-tokens.md)

###### [Service account tokens](https://docs.getdbt.com/docs/dbt-cloud-apis/service-tokens.md)

[Learn how to use service account tokens to securely authenticate with dbt APIs for system-level integrations.](https://docs.getdbt.com/docs/dbt-cloud-apis/service-tokens.md)

#### Types of API access tokens[​](#types-of-api-access-tokens "Direct link to Types of API access tokens")

**Personal access tokens:** Preferred and secure way of accessing dbt APIs on behalf of a user. PATs are scoped to an account and can be enhanced with more granularity and control.

**Service tokens:** Service tokens are similar to service accounts and are the preferred method to enable access on behalf of the dbt account.

##### Which token type should you use[​](#which-token-type-should-you-use "Direct link to Which token type should you use")

You should use service tokens broadly for any production workflow where you need a service account. You should use PATs only for developmental workflows *or* dbt client workflows that require user context. The following examples show you when to use a personal access token (PAT) or a service token:

* **Connecting a partner integration to dbt** — Some examples include the [Semantic Layer Google Sheets integration](https://docs.getdbt.com/docs/cloud-integrations/avail-sl-integrations.md), Hightouch, Datafold, a custom app you’ve created, etc. These types of integrations should use a service token instead of a PAT because service tokens give you visibility, and you can scope them to only what the integration needs and ensure the least privilege. We highly recommend switching to a service token if you’re using a personal access token for these integrations today.
* **Production Terraform** — Use a service token since this is a production workflow and is acting as a service account and not a user account.
* **Cloud CLI** — Use a PAT since the Cloud CLI works within the context of a user (the user is making the requests and has to operate within the context of their user account).
* **Testing a custom script and staging Terraform or Postman** — We recommend using a PAT as this is a developmental workflow and is scoped to the user making the changes. When you push this script or Terraform into production, use a service token instead.
* **API endpoints requiring user context** — Use PATs to authenticate to any API endpoint that requires user context (for example, endpoints to create and update user credentials).

#### Was this page helpful?

[Privacy policy](https://www.getdbt.com/cloud/privacy-policy)[Create a GitHub issue](https://github.com/dbt-labs/docs.getdbt.com/issues)

This site is protected by reCAPTCHA and the Google [Privacy Policy](https://policies.google.com/privacy) and [Terms of Service](https://policies.google.com/terms) apply.

### dbt Administrative API StarterEnterpriseEnterprise +

### dbt Administrative API [Starter](https://www.getdbt.com/pricing "Go to https://www.getdbt.com/pricing")[Enterprise](https://www.getdbt.com/pricing "Go to https://www.getdbt.com/pricing")[Enterprise +](https://www.getdbt.com/pricing "Go to https://www.getdbt.com/pricing")

The dbt Administrative API is enabled by default for [Enterprise and Enterprise+ plans](https://www.getdbt.com/pricing/). It can be used to:

* Download artifacts after a job has completed
* Kick off a job run from an orchestration tool
* Manage your dbt account
* and more

dbt currently supports two versions of the Administrative API: v2 and v3. In general, v3 is the recommended version to use, but we don't yet have all our v2 routes upgraded to v3. We're currently working on this. If you can't find something in our v3 docs, check out the shorter list of v2 endpoints because you might find it there.

Many endpoints of the Administrative API can also be called through the [dbt Terraform provider](https://registry.terraform.io/providers/dbt-labs/dbtcloud/latest). The built-in documentation on the Terraform registry contains [a guide on how to get started with the provider](https://registry.terraform.io/providers/dbt-labs/dbtcloud/latest/docs/guides/1_getting_started) as well as [a page showing all the Terraform resources available](https://registry.terraform.io/providers/dbt-labs/dbtcloud/latest/docs/guides/99_list_resources) to configure.

[![](/img/icons/pencil-paper.svg)](https://docs.getdbt.com/dbt-cloud/api-v2)

###### [API v2](https://docs.getdbt.com/dbt-cloud/api-v2)

[Our legacy API version, with limited endpoints and features. Contains information not available in v3.](https://docs.getdbt.com/dbt-cloud/api-v2)

[![](/img/icons/pencil-paper.svg)](https://docs.getdbt.com/dbt-cloud/api-v3)

###### [API v3](https://docs.getdbt.com/dbt-cloud/api-v3)

[Our latest API version, with new endpoints and features.](https://docs.getdbt.com/dbt-cloud/api-v3)

[![](/img/icons/pencil-paper.svg)](https://registry.terraform.io/providers/dbt-labs/dbtcloud/latest)

###### [dbt Terraform provider](https://registry.terraform.io/providers/dbt-labs/dbtcloud/latest)

[The Terraform provider maintained by dbt Labs which can be used to manage a dbt account.](https://registry.terraform.io/providers/dbt-labs/dbtcloud/latest)

[](https://registry.terraform.io/providers/dbt-labs/dbtcloud/latest)

#### Was this page helpful?

[Privacy policy](https://www.getdbt.com/cloud/privacy-policy)[Create a GitHub issue](https://github.com/dbt-labs/docs.getdbt.com/issues)

This site is protected by reCAPTCHA and the Google [Privacy Policy](https://policies.google.com/privacy) and [Terms of Service](https://policies.google.com/terms) apply.

### Definition object schema

The definition object allows you to query the logical state of a given project node given its most recent manifest generated models.

The [Example queries](#example-queries) illustrate a few fields you can query with this `definition` object. Refer to [Fields](#fields) to view the entire schema, which provides all possible fields you can query.

##### Example queries[​](#example-queries "Direct link to Example queries")

You can use your production environment's `id`:

##### Fields[​](#fields "Direct link to Fields")

When querying the `definition` field of `environment`, you can use the following fields.

#### Was this page helpful?

[Privacy policy](https://www.getdbt.com/cloud/privacy-policy)[Create a GitHub issue](https://github.com/dbt-labs/docs.getdbt.com/issues)

This site is protected by reCAPTCHA and the Google [Privacy Policy](https://policies.google.com/privacy) and [Terms of Service](https://policies.google.com/terms) apply.

### Environment object schema

You can use the environment object to query and compare definition (intended) and applied (actual) states for nodes (models, seeds, snapshots, models, and more) in your dbt project. For example, you specify an `environmentId` to learn more about a particular model (or other node type) in that environment.

The [Example queries](#example-queries) illustrate a few fields you can query with this `environment` object. Refer to [Fields](#fields) to view the entire schema, which provides all possible fields you can query.

##### Arguments[​](#arguments "Direct link to Arguments")

When querying for `environment`, you can use the following arguments.

##### Example queries[​](#example-queries "Direct link to Example queries")

You can use your production environment's `id`:

With the deprecation of the data type `Int` for `id`, below is an example of replacing it with `BigInt`:

With the deprecation of `modelByEnvironment`, below is an example of replacing it with `environment`:

##### Fields[​](#fields "Direct link to Fields")

When querying an `environment`, you can use the following fields.

For details on querying the `applied` field of `environment`, you can visit: [Applied](https://docs.getdbt.com/docs/dbt-cloud-apis/discovery-schema-environment-applied.md)

For details querying the `definition` field of `environment`, you can visit: [Definition](https://docs.getdbt.com/docs/dbt-cloud-apis/discovery-schema-environment-definition.md)

#### Was this page helpful?

[Privacy policy](https://www.getdbt.com/cloud/privacy-policy)[Create a GitHub issue](https://github.com/dbt-labs/docs.getdbt.com/issues)

This site is protected by reCAPTCHA and the Google [Privacy Policy](https://policies.google.com/privacy) and [Terms of Service](https://policies.google.com/terms) apply.

### Exposure object schema

The exposure object allows you to query information about a particular exposure. To learn more, refer to [Add Exposures to your DAG](https://docs.getdbt.com/docs/build/exposures.md).

##### Arguments[​](#arguments "Direct link to Arguments")

When querying for an `exposure`, the following arguments are available.

Below we show some illustrative example queries and outline the schema of the exposure object.

##### Example query[​](#example-query "Direct link to Example query")

The example below queries information about an exposure including the owner's name and email, the URL, and information about parent sources and parent models.

##### Fields[​](#fields "Direct link to Fields")

When querying for an `exposure`, the following fields are available:

#### Was this page helpful?

[Privacy policy](https://www.getdbt.com/cloud/privacy-policy)[Create a GitHub issue](https://github.com/dbt-labs/docs.getdbt.com/issues)

This site is protected by reCAPTCHA and the Google [Privacy Policy](https://policies.google.com/privacy) and [Terms of Service](https://policies.google.com/terms) apply.

### Exposure Tile object schema

[Exposure health tiles](https://docs.getdbt.com/docs/explore/data-tile.md) distill data health signals for data consumers and can be embedded in downstream tools. You can query information on these tiles from the Discovery API.

The [Example query](#example-query) illustrates a few fields you can query with the `exposureTile` object. Refer to [Fields](#fields) to view the entire schema, which provides all possible fields you can query.

##### Arguments[​](#arguments "Direct link to Arguments")

When querying for `exposureTile`, you can use the following arguments:

##### Example query[​](#example-query "Direct link to Example query")

You can specify the `environmentId` and filter by a model's `uniqueId` to understand the data quality and metadata information for the exposure tile associated with the `customers` model in the `marketing` package:

##### Fields[​](#fields "Direct link to Fields")

When querying for `exposureTile`, you can use the following fields:

#### Was this page helpful?

[Privacy policy](https://www.getdbt.com/cloud/privacy-policy)[Create a GitHub issue](https://github.com/dbt-labs/docs.getdbt.com/issues)

This site is protected by reCAPTCHA and the Google [Privacy Policy](https://policies.google.com/privacy) and [Terms of Service](https://policies.google.com/terms) apply.

### Exposures object schema

[Exposures](https://docs.getdbt.com/docs/build/exposures.md) are dbt resources that represent downstream uses of your project, such as dashboards, applications, or data science pipelines. You can query exposures through the Discovery API to understand which assets depend on your models.

The [Example query](#example-query) illustrates a few fields you can query with the `exposures` object. Refer to [Fields](#fields) to view the entire schema, which provides all possible fields you can query.

##### Arguments[​](#arguments "Direct link to Arguments")

When querying for `exposures`, you can use the following arguments:

##### Example query[​](#example-query "Direct link to Example query")

You can specify the `environmentId`, `first: 100`, and filter by model `uniqueIds` to return all the downstream exposures (dashboards, applications, etc.) that depend on the `customers` model in the `marketing` package, limited to the first 100 results:

##### Fields[​](#fields "Direct link to Fields")

When querying for `exposures`, you can use the following fields:

##### Key fields from nodes[​](#key-fields-from-nodes "Direct link to Key fields from nodes")

#### Was this page helpful?

[Privacy policy](https://www.getdbt.com/cloud/privacy-policy)[Create a GitHub issue](https://github.com/dbt-labs/docs.getdbt.com/issues)

This site is protected by reCAPTCHA and the Google [Privacy Policy](https://policies.google.com/privacy) and [Terms of Service](https://policies.google.com/terms) apply.

### Exposures object schema

The exposures object allows you to query information about all exposures in a given job. To learn more, refer to [Add Exposures to your DAG](https://docs.getdbt.com/docs/build/exposures.md).

##### Arguments[​](#arguments "Direct link to Arguments")

When querying for `exposures`, the following arguments are available.

Below we show some illustrative example queries and outline the schema of the exposures object.

##### Example query[​](#example-query "Direct link to Example query")

The example below queries information about all exposures in a given job including the owner's name and email, the URL, and information about parent sources and parent models for each exposure.

##### Fields[​](#fields "Direct link to Fields")

When querying for `exposures`, the following fields are available:

#### Was this page helpful?

[Privacy policy](https://www.getdbt.com/cloud/privacy-policy)[Create a GitHub issue](https://github.com/dbt-labs/docs.getdbt.com/issues)

This site is protected by reCAPTCHA and the Google [Privacy Policy](https://policies.google.com/privacy) and [Terms of Service](https://policies.google.com/terms) apply.

### GraphQL StarterEnterpriseEnterprise +

### GraphQL [Starter](https://www.getdbt.com/pricing "Go to https://www.getdbt.com/pricing")[Enterprise](https://www.getdbt.com/pricing "Go to https://www.getdbt.com/pricing")[Enterprise +](https://www.getdbt.com/pricing "Go to https://www.getdbt.com/pricing")

[GraphQL](https://graphql.org/) (GQL) is an open-source query language for APIs. It offers a more efficient and flexible approach compared to traditional RESTful APIs.

With GraphQL, users can request specific data using a single query, reducing the need for many server round trips. This improves performance and minimizes network overhead.

GraphQL has several advantages, such as self-documenting, having a strong typing system, supporting versioning and evolution, enabling rapid development, and having a robust ecosystem. These features make GraphQL a powerful choice for APIs prioritizing flexibility, performance, and developer productivity.

#### dbt Semantic Layer GraphQL API[​](#dbt-semantic-layer-graphql-api "Direct link to dbt Semantic Layer GraphQL API")

The Semantic Layer GraphQL API allows you to explore and query metrics and dimensions. Due to its self-documenting nature, you can explore the calls conveniently through a schema explorer.

The schema explorer URLs vary depending on your [deployment region](https://docs.getdbt.com/docs/cloud/about-cloud/access-regions-ip-addresses.md). Use the following table to find the right link for your region:

| Deployment type            | Schema explorer URL                                                                                                                                                                                                   |
| -------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| North America multi-tenant | <https://semantic-layer.cloud.getdbt.com/api/graphql>                                                                                                                                                                 |
| EMEA multi-tenant          | <https://semantic-layer.emea.dbt.com/api/graphql>                                                                                                                                                                     |
| APAC multi-tenant          | <https://semantic-layer.au.dbt.com/api/graphql>                                                                                                                                                                       |
| Single tenant              | `https://semantic-layer.YOUR_ACCESS_URL/api/graphql`<br /><br />Replace `YOUR_ACCESS_URL` with your specific account prefix followed by the appropriate Access URL for your region and plan.                          |
| Multi-cell                 | `https://YOUR_ACCOUNT_PREFIX.semantic-layer.REGION.dbt.com/api/graphql`<br /><br />Replace `YOUR_ACCOUNT_PREFIX` with your specific account identifier and `REGION` with your location, which could be `us1.dbt.com`. |

* If your Single tenant access URL is `ABC123.getdbt.com`, your schema explorer URL will be `https://semantic-layer.ABC123.getdbt.com/api/graphql`.

dbt Partners can use the Semantic Layer GraphQL API to build an integration with the Semantic Layer.

Note that the Semantic Layer GraphQL API doesn't support `ref` to call dbt objects. Instead, use the complete qualified table name. If you're using dbt macros at query time to calculate your metrics, you should move those calculations into your Semantic Layer metric definitions as code.

#### Requirements to use the GraphQL API[​](#requirements-to-use-the-graphql-api "Direct link to Requirements to use the GraphQL API")

* A dbt project on dbt v1.6 or higher
* Metrics are defined and configured
* A dbt [service token](https://docs.getdbt.com/docs/dbt-cloud-apis/service-tokens.md) with "Semantic Layer Only” and "Metadata Only" permissions or a [personal access token](https://docs.getdbt.com/docs/dbt-cloud-apis/user-tokens.md)

#### Using the GraphQL API[​](#using-the-graphql-api "Direct link to Using the GraphQL API")

If you're a dbt user or partner with access to dbt and the [Semantic Layer](https://docs.getdbt.com/docs/use-dbt-semantic-layer/dbt-sl.md), you can [set up](https://docs.getdbt.com/docs/use-dbt-semantic-layer/setup-sl.md) and test this API with data from your own instance by configuring the Semantic Layer and obtaining the right GQL connection parameters described in this document.

Refer to [Get started with the Semantic Layer](https://docs.getdbt.com/guides/sl-snowflake-qs.md) for more info.

Authentication uses either a dbt [service account token](https://docs.getdbt.com/docs/dbt-cloud-apis/service-tokens.md) or a [personal access token](https://docs.getdbt.com/docs/dbt-cloud-apis/user-tokens.md) passed through a header as follows. To explore the schema, you can enter this information in the "header" section.

Each GQL request also requires a dbt `environmentId`. The API uses both the service or personal token in the header and `environmentId` for authentication.

##### Metadata calls[​](#metadata-calls "Direct link to Metadata calls")

###### Fetch data platform dialect[​](#fetch-data-platform-dialect "Direct link to Fetch data platform dialect")

In some cases in your application, it may be useful to know the dialect or data platform that's internally used for the Semantic Layer connection (such as if you are building `where` filters from a user interface rather than user-inputted SQL).

The GraphQL API has an easy way to fetch this with the following query:

###### Fetch available metrics[​](#fetch-available-metrics "Direct link to Fetch available metrics")

###### Fetch available dimensions for metrics[​](#fetch-available-dimensions-for-metrics "Direct link to Fetch available dimensions for metrics")

###### Fetch available granularities given metrics[​](#fetch-available-granularities-given-metrics "Direct link to Fetch available granularities given metrics")

Note: This call for `queryableGranularities` returns only queryable granularities for metric time - the primary time dimension across all metrics selected.

You can also get queryable granularities for all other dimensions using the `dimensions` call:

You can also optionally access it from the metrics endpoint:

###### Fetch measures[​](#fetch-measures "Direct link to Fetch measures")

`aggTimeDimension` tells you the name of the dimension that maps to `metric_time` for a given measure. You can also query `measures` from the `metrics` endpoint, which allows you to see what dimensions map to `metric_time` for a given metric:

###### Fetch entities[​](#fetch-entities "Direct link to Fetch entities")

###### Fetch entities and dimensions to group metrics[​](#fetch-entities-and-dimensions-to-group-metrics "Direct link to Fetch entities and dimensions to group metrics")

###### Metric types[​](#metric-types "Direct link to Metric types")

###### Metric type parameters[​](#metric-type-parameters "Direct link to Metric type parameters")

###### Dimension types[​](#dimension-types "Direct link to Dimension types")

###### List saved queries[​](#list-saved-queries "Direct link to List saved queries")

List all saved queries for the specified environment:

###### List a saved query[​](#list-a-saved-query "Direct link to List a saved query")

List a single saved query using environment ID and query name:

##### Querying[​](#querying "Direct link to Querying")

When querying for data, *either* a `groupBy` *or* a `metrics` selection is required. The following section provides examples of how to query metrics:

* [Create query](#create-metric-query)
* [Fetch query result](#fetch-query-result)

###### Create query[​](#create-query "Direct link to Create query")

###### Fetch query result[​](#fetch-query-result "Direct link to Fetch query result")

The GraphQL API uses a polling process for querying since queries can be long-running in some cases. It works by first creating a query with a mutation, \`createQuery, which returns a query ID. This ID is then used to continuously check (poll) for the results and status of your query. The typical flow would look as follows:

3. Keep querying 2. at an appropriate interval until status is `FAILED` or `SUCCESSFUL`

##### Output format and pagination[​](#output-format-and-pagination "Direct link to Output format and pagination")

###### Output format[​](#output-format "Direct link to Output format")

By default, the output is in Arrow format. You can switch to JSON format using the following parameter. However, due to performance limitations, we recommend using the JSON parameter for testing and validation. The JSON received is a base64 encoded string. To access it, you can decode it using a base64 decoder. The JSON is created from pandas, which means you can change it back to a dataframe using `pandas.read_json(json, orient="table")`. Or you can work with the data directly using `json["data"]`, and find the table schema using `json["schema"]["fields"]`. Alternatively, you can pass `encoded:false` to the jsonResult field to get a raw JSON string directly.

The results default to the table but you can change it to any [pandas](https://pandas.pydata.org/pandas-docs/stable/reference/api/pandas.DataFrame.to_json.html) supported value.

###### Pagination[​](#pagination "Direct link to Pagination")

By default, we return 1024 rows per page. If your result set exceeds this, you need to increase the page number using the `pageNum` option.

##### Run a Python query[​](#run-a-python-query "Direct link to Run a Python query")

The `arrowResult` in the GraphQL query response is a byte dump, which isn't visually useful. You can convert this byte data into an Arrow table using any Arrow-supported language. Refer to the following Python example explaining how to query and decode the arrow result:

```
import base64
import pyarrow as pa
import time

headers = {"Authorization":"Bearer <token>"}
query_result_request = """
{
  query(environmentId: 70, queryId: "12345678") {
    sql
    status
    error
    arrowResult
  }
}
"""

while True:
  gql_response = requests.post(
    "https://semantic-layer.cloud.getdbt.com/api/graphql",
    json={"query": query_result_request},
    headers=headers,
  )
  if gql_response.json()["data"]["status"] in ["FAILED", "SUCCESSFUL"]:
    break
  # Set an appropriate interval between polling requests
  time.sleep(1)

"""
gql_response.json() => 
{
  "data": {
    "query": {
      "sql": "SELECT\n  ordered_at AS metric_time__day\n  , SUM(order_total) AS order_total\nFROM semantic_layer.orders orders_src_1\nGROUP BY\n  ordered_at",
      "status": "SUCCESSFUL",
      "error": null,
      "arrowResult": "arrow-byte-data"
    }
  }
}
"""

def to_arrow_table(byte_string: str) -> pa.Table:
  """Get a raw base64 string and convert to an Arrow Table."""
  with pa.ipc.open_stream(base64.b64decode(byte_string)) as reader:
    return pa.Table.from_batches(reader, reader.schema)

arrow_table = to_arrow_table(gql_response.json()["data"]["query"]["arrowResult"])

**Examples:**

Example 1 (unknown):
```unknown
query Example {
	environment(id: 834){ # Get the latest state of the production environment
		applied { # The state of an executed node as it exists as an object in the database
			models(first: 100){ # Pagination to ensure manageable response for large projects
				edges { node {
					uniqueId, name, description, rawCode, compiledCode, # Basic properties
					database, schema, alias, # Table/view identifier (can also filter by)
					executionInfo {executeCompletedAt, executionTime}, # Metadata from when the model was built
					tests {name, executionInfo{lastRunStatus, lastRunError}}, # Latest test results
					catalog {columns {name, description, type}, stats {label, value}}, # Catalog info
					ancestors(types:[Source]) {name, ...on SourceAppliedStateNestedNode {freshness{maxLoadedAt, freshnessStatus}}}, # Source freshness }
					children {name, resourceType}}} # Immediate dependencies in lineage
				totalCount } # Number of models in the project
		}
	}
}
```

Example 2 (unknown):
```unknown
query Example {
	environment(id: 834){ # Get the latest state of the production environment
		definition { # The logical state of a given project node given its most recent manifest generated
			models(first: 100, filter:{access:public}){ # Filter on model access (or other properties)
				edges { node {
					rawCode, # Compare to see if/how the model has changed since the last build
					jobDefinitionId, runGeneratedAt,	# When the code was last compiled or run
					contractEnforced, group, version}}} # Model governance
		}
	}
}
```

Example 3 (unknown):
```unknown
query Example {
	environment(id: 834){ # Get the latest state of the production environment
		applied { # The state of an executed node as it exists as an object in the database
			models(first: 100){ # Pagination to ensure manageable response for large projects
				edges { node {
					uniqueId, name, description, rawCode, compiledCode, # Basic properties
					database, schema, alias, # Table/view identifier (can also filter by)
					executionInfo {executeCompletedAt, executionTime}, # Metadata from when the model was built
					tests {name, executionInfo{lastRunStatus, lastRunError}}, # Latest test results
					catalog {columns {name, description, type}, stats {label, value}}, # Catalog info
					ancestors(types:[Source]) {name, ...on SourceAppliedStateNode {freshness{maxLoadedAt, freshnessStatus}}}, # Source freshness }
					children {name, resourceType}}} # Immediate dependencies in lineage
				totalCount } # Number of models in the project
		}
		definition { # The logical state of a given project node given its most recent manifest generated
			models(first: 100, filter:{access:public}){ # Filter on model access (or other properties)
				edges { node {
					rawCode, # Compare to see if/how the model has changed since the last build
					jobDefinitionId, runGeneratedAt,	# When the code was last compiled or run
					contractEnforced, group, version}}} # Model governance
		}
	}
```

Example 4 (unknown):
```unknown
query ($environmentId: BigInt!, $first: Int!) {
  environment(id: $environmentId) {
    applied {
      models(first: $first) {
        edges {
          node {
            uniqueId
            executionInfo {
              lastRunId
            }
          }
        }
      }
    }
  }
}
```

---

## These are documented on the dbt API docs

**URL:** llms-txt#these-are-documented-on-the-dbt-api-docs

**Contents:**
  - Use Jinja to improve your SQL code
  - Using BigQuery DataFrames with dbt Python models
- Navigation Options
  - navigation-options
- Platform
  - About Canvas EnterpriseEnterprise +
  - About Canvas [Enterprise](https://www.getdbt.com/pricing "Go to https://www.getdbt.com/pricing")[Enterprise +](https://www.getdbt.com/pricing "Go to https://www.getdbt.com/pricing")
  - About cost management Private previewEnterpriseEnterprise +
  - About cost management [Private preview](https://docs.getdbt.com/docs/dbt-versions/product-lifecycles "Go to https://docs.getdbt.com/docs/dbt-versions/product-lifecycles")[Enterprise](https://www.getdbt.com/pricing "Go to https://www.getdbt.com/pricing")[Enterprise +](https://www.getdbt.com/pricing "Go to https://www.getdbt.com/pricing")
  - About dbt Copilot StarterEnterpriseEnterprise +

class DbtJobRunStatus(enum.IntEnum):
    QUEUED = 1
    STARTING = 2
    RUNNING = 3
    SUCCESS = 10
    ERROR = 20
    CANCELLED = 30

def _trigger_job() -> int:
    res = requests.post(
        url=f"https://{base_url}/api/v2/accounts/{account_id}/jobs/{job_id}/run/",
        headers={'Authorization': f"Token {api_key}"},
        json={
            # Optionally pass a description that can be viewed within the <Constant name="cloud" /> API.
            # See the API docs for additional parameters that can be passed in,
            # including `schema_override` 
            'cause': f"Triggered by Databricks Workflows.",
        }
    )

try:
        res.raise_for_status()
    except:
        print(f"API token (last four): ...{api_key[-4:]}")
        raise

response_payload = res.json()
    return response_payload['data']['id']

def _get_job_run_status(job_run_id):
    res = requests.get(
        url=f"https://{base_url}/api/v2/accounts/{account_id}/runs/{job_run_id}/",
        headers={'Authorization': f"Token {api_key}"},
    )

res.raise_for_status()
    response_payload = res.json()
    return response_payload['data']['status']

def run():
    job_run_id = _trigger_job()
    print(f"job_run_id = {job_run_id}")   
    while True:
        time.sleep(5)
        status = _get_job_run_status(job_run_id)
        print(DbtJobRunStatus(status))
        if status == DbtJobRunStatus.SUCCESS:
            break
        elif status == DbtJobRunStatus.ERROR or status == DbtJobRunStatus.CANCELLED:
            raise Exception("Failure!")

if __name__ == '__main__':
    run()

job_run_id = 123456
DbtJobRunStatus.QUEUED
DbtJobRunStatus.QUEUED
DbtJobRunStatus.QUEUED
DbtJobRunStatus.STARTING
DbtJobRunStatus.RUNNING
DbtJobRunStatus.RUNNING
DbtJobRunStatus.RUNNING
DbtJobRunStatus.RUNNING
DbtJobRunStatus.RUNNING
DbtJobRunStatus.RUNNING
DbtJobRunStatus.RUNNING
DbtJobRunStatus.RUNNING
DbtJobRunStatus.SUCCESS

select
order_id,
sum(case when payment_method = 'bank_transfer' then amount end) as bank_transfer_amount,
sum(case when payment_method = 'credit_card' then amount end) as credit_card_amount,
sum(case when payment_method = 'gift_card' then amount end) as gift_card_amount,
sum(amount) as total_amount
from {{ ref('raw_payments') }}
group by 1

select
order_id,
{% for payment_method in ["bank_transfer", "credit_card", "gift_card"] %}
sum(case when payment_method = '{{payment_method}}' then amount end) as {{payment_method}}_amount,
{% endfor %}
sum(amount) as total_amount
from {{ ref('raw_payments') }}
group by 1

{% set payment_methods = ["bank_transfer", "credit_card", "gift_card"] %}

select
order_id,
{% for payment_method in payment_methods %}
sum(case when payment_method = '{{payment_method}}' then amount end) as {{payment_method}}_amount,
{% endfor %}
sum(amount) as total_amount
from {{ ref('raw_payments') }}
group by 1

{% set payment_methods = ["bank_transfer", "credit_card", "gift_card"] %}

select
order_id,
{% for payment_method in payment_methods %}
sum(case when payment_method = '{{payment_method}}' then amount end) as {{payment_method}}_amount
{% if not loop.last %},{% endif %}
{% endfor %}
from {{ ref('raw_payments') }}
group by 1

sum(case when payment_method = 'bank_transfer' then amount end) as bank_transfer_amount
,

sum(case when payment_method = 'credit_card' then amount end) as credit_card_amount
,

sum(case when payment_method = 'gift_card' then amount end) as gift_card_amount

from raw_jaffle_shop.payments
group by 1

{%- set payment_methods = ["bank_transfer", "credit_card", "gift_card"] -%}

select
order_id,
{%- for payment_method in payment_methods %}
sum(case when payment_method = '{{payment_method}}' then amount end) as {{payment_method}}_amount
{%- if not loop.last %},{% endif -%}
{% endfor %}
from {{ ref('raw_payments') }}
group by 1

{% macro get_payment_methods() %}
{{ return(["bank_transfer", "credit_card", "gift_card"]) }}
{% endmacro %}

{%- set payment_methods = get_payment_methods() -%}

select
order_id,
{%- for payment_method in payment_methods %}
sum(case when payment_method = '{{payment_method}}' then amount end) as {{payment_method}}_amount
{%- if not loop.last %},{% endif -%}
{% endfor %}
from {{ ref('raw_payments') }}
group by 1

select distinct
payment_method
from {{ ref('raw_payments') }}
order by 1

{% macro get_payment_methods() %}

{% set payment_methods_query %}
select distinct
payment_method
from {{ ref('raw_payments') }}
order by 1
{% endset %}

{% set results = run_query(payment_methods_query) %}

{{ log(results, info=True) }}

| column         | data_type |
| -------------- | --------- |
| payment_method | Text      |

{% macro get_payment_methods() %}

{% set payment_methods_query %}
select distinct
payment_method
from {{ ref('raw_payments') }}
order by 1
{% endset %}

{% set results = run_query(payment_methods_query) %}

{% if execute %}
{# Return the first column #}
{% set results_list = results.columns[0].values() %}
{% else %}
{% set results_list = [] %}
{% endif %}

{{ return(results_list) }}

{% macro get_column_values(column_name, relation) %}

{% set relation_query %}
select distinct
{{ column_name }}
from {{ relation }}
order by 1
{% endset %}

{% set results = run_query(relation_query) %}

{% if execute %}
{# Return the first column #}
{% set results_list = results.columns[0].values() %}
{% else %}
{% set results_list = [] %}
{% endif %}

{{ return(results_list) }}

{% macro get_payment_methods() %}

{{ return(get_column_values('payment_method', ref('raw_payments'))) }}

{%- set payment_methods = dbt_utils.get_column_values(
    table=ref('raw_payments'),
    column='payment_method'
) -%}

select
order_id,
{%- for payment_method in payment_methods %}
sum(case when payment_method = '{{payment_method}}' then amount end) as {{payment_method}}_amount
{%- if not loop.last %},{% endif -%}
{% endfor %}
from {{ ref('raw_payments') }}
group by 1

#Create Service Account
   gcloud iam service-accounts create dbt-bigframes-sa
   #Grant BigQuery User Role
   gcloud projects add-iam-policy-binding ${GOOGLE_CLOUD_PROJECT} --member=serviceAccount:dbt-bigframes-sa@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com --role=roles/bigquery.user
   #Grant BigQuery Data Editor role. This can be restricted at dataset level
   gcloud projects add-iam-policy-binding ${GOOGLE_CLOUD_PROJECT} --member=serviceAccount:dbt-bigframes-sa@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com --role=roles/bigquery.dataEditor
   #Grant Service Account user 
   gcloud projects add-iam-policy-binding ${GOOGLE_CLOUD_PROJECT} --member=serviceAccount:dbt-bigframes-sa@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com --role=roles/iam.serviceAccountUser
   #Grant Colab Entperprise User
   gcloud projects add-iam-policy-binding ${GOOGLE_CLOUD_PROJECT} --member=serviceAccount:dbt-bigframes-sa@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com --role=roles/aiplatform.colabEnterpriseUser
   
   #Create BQ dataset 
   bq mk --location=${REGION} echo "${GOOGLE_CLOUD_PROJECT}" | tr '-' '_'_dataset
   
   #Create GCS bucket
   gcloud storage buckets create gs://${GOOGLE_CLOUD_PROJECT}-bucket --location=${REGION}
   #Grant Storage Admin over the bucket to your SA

gcloud storage buckets add-iam-policy-binding gs://${GOOGLE_CLOUD_PROJECT}-bucket --member=serviceAccount:dbt-bigframes-sa@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com --role=roles/storage.admin
   
      select 
      1 as foo,
      2 as bar
   
   def model(dbt, session):
      dbt.config(submission_method="bigframes")
      bdf = dbt.ref("my_sql_model") #loading from prev step
      return bdf
   
   models:
   my_dbt_project:
      submission_method: bigframes
      python_models:
         +materialized: view
   
   def model(dbt, session):
      dbt.config(submission_method="bigframes")
      # rest of the python code...

CREATE USER dbt_cost_user
  PASSWORD = 'A_SECURE_PASSWORD'
  DEFAULT_ROLE = dbt_cost_management
  MUST_CHANGE_PASSWORD = FALSE;

CREATE ROLE dbt_cost_management;

GRANT ROLE dbt_cost_management TO USER dbt_cost_user;

GRANT USAGE ON DATABASE SNOWFLAKE TO ROLE dbt_cost_management;
GRANT USAGE ON SCHEMA SNOWFLAKE.ACCOUNT_USAGE TO ROLE dbt_cost_management;
GRANT USAGE ON WAREHOUSE YOUR_WAREHOUSE TO ROLE dbt_cost_management;
ALTER USER dbt_cost_user SET DEFAULT_WAREHOUSE = 'YOUR_WAREHOUSE';

GRANT SELECT ON VIEW SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY TO ROLE dbt_cost_management;
GRANT SELECT ON VIEW SNOWFLAKE.ACCOUNT_USAGE.QUERY_ATTRIBUTION_HISTORY TO ROLE dbt_cost_management;
GRANT SELECT ON VIEW SNOWFLAKE.ACCOUNT_USAGE.ACCESS_HISTORY TO ROLE dbt_cost_management;
GRANT SELECT ON VIEW SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY TO ROLE dbt_cost_management;

GRANT USAGE ON SCHEMA SNOWFLAKE.ORGANIZATION_USAGE TO ROLE dbt_cost_management;
GRANT SELECT ON VIEW SNOWFLAKE.ORGANIZATION_USAGE.USAGE_IN_CURRENCY_DAILY TO ROLE dbt_cost_management;

CREATE USER dbt_cost_user
  PASSWORD = 'A_SECURE_PASSWORD'
  DEFAULT_ROLE = dbt_cost_management
  MUST_CHANGE_PASSWORD = FALSE;

CREATE ROLE dbt_cost_management;
GRANT IMPORTED PRIVILEGES ON DATABASE SNOWFLAKE TO ROLE dbt_cost_management;
GRANT ROLE dbt_cost_management TO USER dbt_cost_user;

dbt sl query --metrics revenue --group-by metric_time
  
  dbt sl query --metrics revenue --group-by metric_time,user__country
  
  dbt sl query --metrics revenue,gross_sales --group-by metric_time,user__country
  
  dbt sl query --metrics revenue --group-by metric_time --compile
  
  dbt sl query --metrics revenue,gross_sales --group-by metric_time --compile
  
    selectors:
      - name: skip_views_but_test_views
        description: >
          A default selector that will exclude materializing views
          without skipping tests on views.
        default: true
        definition:
          union:
            - union: 
              - method: path
                value: "*"
              - exclude: 
                - method: config.materialized
                  value: view
            - method: resource_type
              value: test
   
   version: "1"
   context:
     active-project: "<project id from the list below>"
     active-host: "<active host from the list>"
     defer-env-id: "<optional defer environment id>"
   projects:
     - project-name: "<project-name>"
       project-id: "<project-id>"
       account-name: "<account-name>"
       account-id: "<account-id>"
       account-host: "<account-host>" # for example, "cloud.getdbt.com"
       token-name: "<pat-name>"
       token-value: "<pat-value>"

- project-name: "<project-name>"
       project-id: "<project-id>"
       account-name: "<account-name>"
       account-id: "<account-id>"
       account-host: "<account-host>" # for example, "cloud.getdbt.com"
       token-name: "<pat-name>"
       token-value: "<pat-value>"  
   
   cd ~/dbt-projects/jaffle_shop
   
   # dbt_project.yml
   name:
   version:
   # Your project configs...

dbt-cloud: 
       project-id: PROJECT_ID
   
dbt sqlfluff lint [PATHS]... [flags]

**Examples:**

Example 1 (unknown):
```unknown
3. Replace **`<YOUR_SECRET_SCOPE>`** and **`<YOUR_SECRET_KEY>`** with the values you used [previously](#set-up-a-databricks-secret-scope)

4. Replace **`<YOUR_BASE_URL>`** and **`<YOUR_ACCOUNT_ID>`** with the correct values of your environment and [Access URL](https://docs.getdbt.com/docs/cloud/about-cloud/access-regions-ip-addresses.md) for your region and plan.

   * To find these values, navigate to dbt, select **Deploy -> Jobs**. Select the Job you want to run and copy the URL. For example: `https://YOUR_ACCESS_URL/deploy/000000/projects/111111/jobs/222222` and therefore valid code would be:

Your URL is structured `https://<YOUR_BASE_URL>/deploy/<YOUR_ACCOUNT_ID>/projects/<YOUR_PROJECT_ID>/jobs/<YOUR_JOB_ID>` account\_id = 000000 job\_id = 222222 base\_url = "cloud.getdbt.com"

5. Run the Notebook. It will fail, but you should see **a `job_id` widget** at the top of your notebook.

6. In the widget, **enter your `job_id`** from step 4.

7. **Run the Notebook again** to trigger the dbt job. Your results should look similar to the following:
```

Example 2 (unknown):
```unknown
You can cancel the job from dbt if necessary.

#### Configure the workflows to run the dbt jobs[​](#configure-the-workflows-to-run-the-dbt-jobs "Direct link to Configure the workflows to run the dbt jobs")

You can set up workflows directly from the notebook OR by adding this notebook to one of your existing workflows:

* Create a workflow from existing Notebook
* Add the Notebook to existing workflow

1. Click **Schedule** on the upper right side of the page
2. Click **Add a schedule**
3. Configure Job name, Schedule, Cluster
4. Add a new parameter called: `job_id` and fill in your job ID. Refer to [step 4 in previous section](#create-a-databricks-python-notebook) to find your job ID.
5. Click **Create**
6. Click **Run Now** to test the job

1) Open Existing **Workflow**
2) Click **Tasks**
3) Press **“+” icon** to add a new task
4) Enter the **following**:

| Field      | Value                         |
| ---------- | ----------------------------- |
| Task name  | `<unique_task_name>`          |
| Type       | Notebook                      |
| Source     | Workspace                     |
| Path       | `</path/to/notebook>`         |
| Cluster    | `<your_compute_cluster>`      |
| Parameters | `job_id`: `<your_dbt_job_id>` |

5. Select **Save Task**
6. Click **Run Now** to test the workflow

Multiple Workflow tasks can be set up using the same notebook by configuring the `job_id` parameter to point to different dbt jobs.

Using Databricks workflows to access the dbt job API can improve integration of your data pipeline processes and enable scheduling of more complex workflows.

#### Was this page helpful?

YesNo

[Privacy policy](https://www.getdbt.com/cloud/privacy-policy)[Create a GitHub issue](https://github.com/dbt-labs/docs.getdbt.com/issues)

This site is protected by reCAPTCHA and the Google [Privacy Policy](https://policies.google.com/privacy) and [Terms of Service](https://policies.google.com/terms) apply.


---

### Use Jinja to improve your SQL code

[Back to guides](https://docs.getdbt.com/guides.md)

Jinja

dbt Core

Advanced

[Menu ]()

#### Introduction[​](#introduction "Direct link to Introduction")

In this guide, we're going to take a common pattern used in SQL, and then use Jinja to improve our code.

If you'd like to work through this query, add [this CSV](https://github.com/dbt-labs/jaffle_shop/blob/core-v1.0.0/seeds/raw_payments.csv) to the `seeds/` folder of your dbt project, and then execute `dbt seed`.

While working through the steps of this model, we recommend that you have your compiled SQL open as well, to check what your Jinja compiles to. To do this:

* **Using dbt:** Click the compile button to see the compiled SQL in the right hand pane
* **Using dbt Core:** Run `dbt compile` from the command line. Then open the compiled SQL file in the `target/compiled/{project name}/` directory. Use a split screen in your code editor to keep both files open at once.

#### Write the SQL without Jinja[​](#write-the-sql-without-jinja "Direct link to Write the SQL without Jinja")

Consider a data model in which an `order` can have many `payments`. Each `payment` may have a `payment_method` of `bank_transfer`, `credit_card` or `gift_card`, and therefore each `order` can have multiple `payment_methods`

From an analytics perspective, it's important to know how much of each `order` was paid for with each `payment_method`. In your dbt project, you can create a model, named `order_payment_method_amounts`, with the following SQL:

models/order\_payment\_method\_amounts.sql
```

Example 3 (unknown):
```unknown
The SQL for each payment method amount is repetitive, which can be difficult to maintain for a number of reasons:

* If the logic or field name were to change, the code would need to be updated in three places.
* Often this code is created by copying and pasting, which may lead to mistakes.
* Other analysts that review the code are less likely to notice errors as it's common to only scan through repeated code.

So we're going to use Jinja to help us clean it up, or to make our code more "DRY" ("Don't Repeat Yourself").

#### Use a for loop in models for repeated SQL[​](#use-a-for-loop-in-models-for-repeated-sql "Direct link to Use a for loop in models for repeated SQL")

Here, the repeated code can be replaced with a `for` loop. The following will be compiled to the same query, but is significantly easier to maintain.

/models/order\_payment\_method\_amounts.sql
```

Example 4 (unknown):
```unknown
#### Set variables at the top of a model[​](#set-variables-at-the-top-of-a-model "Direct link to Set variables at the top of a model")

We recommend setting variables at the top of a model, as it helps with readability, and enables you to reference the list in multiple places if required. This is a practice we've borrowed from many other programming languages.

/models/order\_payment\_method\_amounts.sql
```

---

## Get the historical run metadata for the longest running model

**URL:** llms-txt#get-the-historical-run-metadata-for-the-longest-running-model

model_historical_metadata = query_discovery_api(auth_token, query_two, variables_query_two)['environment']['applied']['modelHistoricalRuns']

---

## ... initialize client

**URL:** llms-txt#...-initialize-client

**Contents:**
  - Query the Discovery API
  - Resources object schema
  - Fetching data...
  - Fetching data...
  - Fetching data...
  - Seed object schema
  - Fetching data...
  - Fetching data...
  - Seeds object schema
  - Fetching data...

curl 'YOUR_API_URL' \
    -H 'authorization: Bearer YOUR_TOKEN' \
    -H 'content-type: application/json'
    -X POST
    --data QUERY_BODY
  
response = requests.post(
    'YOUR_API_URL',
    headers={"authorization": "Bearer "+YOUR_TOKEN, "content-type": "application/json"},
    json={"query": QUERY_BODY, "variables": VARIABLES}
)

metadata = response.json()['data'][ENDPOINT]

query ($environmentId: BigInt!, $first: Int!) {
  environment(id: $environmentId) {
    applied {
      models(first: $first, filter: { uniqueIds: "MODEL.PROJECT.MODEL_NAME" }) {
        edges {
          node {
            name
            ancestors(types: [Model, Source, Seed, Snapshot]) {
              ... on ModelAppliedStateNestedNode {
                name
                resourceType
                materializedType
                executionInfo {
                  executeCompletedAt
                }
              }
              ... on SourceAppliedStateNestedNode {
                sourceName
                name
                resourceType
                freshness {
                  maxLoadedAt
                }
              }
              ... on SnapshotAppliedStateNestedNode {
                name
                resourceType
                executionInfo {
                  executeCompletedAt
                }
              }
              ... on SeedAppliedStateNestedNode {
                name
                resourceType
                executionInfo {
                  executeCompletedAt
                }
              }
            }
          }
        }
      }
    }
  }
}

pageInfo {
  startCursor
  endCursor
  hasNextPage
}
totalCount # Total number of records across all pages

query ModelsAndTests($environmentId: BigInt!, $first: Int!) {
  environment(id: $environmentId) {
    applied {
      models(first: $first, filter: { lastRunStatus: error }) {
        edges {
          node {
            name
            executionInfo {
              lastRunId
            }
          }
        }
      }
      tests(first: $first, filter: { status: "fail" }) {
        edges {
          node {
            name
            executionInfo {
              lastRunId
            }
          }
        }
      }
    }
  }
}

query {
  environment(id: 834) {
    applied {
      resources(
        filter: {
          types: [
            Model
          ]
        }, 
        first: 100
      ) {
        edges {
          node {
            accountId
            description
            environmentId
            filePath
            meta
            name
            projectId
            resourceType
            uniqueId
            tags
          }
        }
      }
    }
  }
}

{
  job(id: 123) {
    seed(uniqueId: "seed.jaffle_shop.raw_customers") {
      database
      schema
      uniqueId
      name
      status
      error
    }
  }
}

query ($environmentId: BigInt!, $first: Int!, $filter: GenericMaterializedFilter) {
  environment(id: $environmentId) {
    applied {
      seeds(
        first: 100,
        filter: {
          database: "analytics"
        }
      ) {
        edges {
          node {
            description
            name
            filePath
            projectId
            fqn
            tags
            uniqueId
            resourceType
          }
        }
      }
    }
  }
}

{
  job(id: 123) {
    seeds {
      uniqueId
      name
      executionTime
      status
    }
  }
}

{
            "status": {
                "code": 403,
                "is_success": False,
                "user_message": ("Forbidden: Access denied"),
                "developer_message": None,
            },
            "data": {
                "account_id": <account_id>,
                "user_id": <user_id>,
                "is_service_token": <boolean describing if it's a service token request>,
                "account_access_denied": True,
            },
        }

query {
  environment(id: 834) {
    applied {
      snapshots(
        filter: {
          database: "analytics"
        }, 
        first: 100
      ) {
        edges {
          node {
            executionInfo {
              compileCompletedAt
              compileStartedAt
              executeCompletedAt
              executeStartedAt
              executionTime
              lastRunStatus
              lastRunId
            }
            fqn
            name
          }
        }
      }
    }
  }
}

{
  job(id: 123) {
    snapshots {
      uniqueId
      name
      executionTime
      environmentId
      executeStartedAt
      executeCompletedAt
    }
  }
}

{
  job(id: 123) {
    source(uniqueId: "source.jaffle_shop.snowplow.event") {
      uniqueId
      sourceName
      name
      state
      maxLoadedAt
      criteria {
        warnAfter {
          period
          count
        }
        errorAfter {
          period
          count
        }
      }
      maxLoadedAtTimeAgoInS
    }
  }
}

query {
  environment(id: 834) {
    applied {
      sources(
        filter: {
          database: "analytics"
        }, 
        first: 100
      ) {
        edges {
          node {
            name
            fqn
            description
            filePath
            freshness {
              freshnessChecked
              freshnessStatus
            }
            sourceName
            sourceDescription
            tests {
              name
              description
              testType
              executionInfo {
                lastRunStatus
              }
            }
          }
        }
      }
    }
  }
}

{
  job(id: 123) {
    sources(
      database: "analytics"
      schema: "analytics"
      identifier: "dim_customers"
    ) {
      uniqueId
    }
  }
}

{
  job(id: 123) {
    sources(schema: "analytics") {
      uniqueId
      state
    }
  }
}

query {
  environment(id: 834) {
    applied {
      tags {
        name
      }
    }
  }
}

{
  job(id: 123) {
    test(uniqueId: "test.internal_analytics.not_null_metrics_id") {
      runId
      accountId
      projectId
      uniqueId
      name
      columnName
      state
    }
  }
}

query {
  environment(id: 834) {
    applied {
      tests(
        filter: {
          testTypes: [
            GENERIC_DATA_TEST,
            SINGULAR_DATA_TEST,
            UNIT_TEST
          ]
        }, 
        first: 100
      ) {
        edges {
          node {
            name
            model
            description
            expect
            resourceType
            testType
            given
          }
        }
      }
    }
  }
}

{
  job(id: 123) {
    tests {
      runId
      accountId
      projectId
      uniqueId
      name
      columnName
      state
    }
  }
}

query AppliedModels($environmentId: BigInt!, $first: Int!) {
  environment(id: $environmentId) {
    applied {
      models(first: $first) {
        edges {
          node {
            name
            uniqueId
            materializedType
            executionInfo {
              lastSuccessRunId
              executionTime
              executeStartedAt
            }
          }
        }
      }
    }
  }
}

query ModelHistoricalRuns(
  $environmentId: BigInt!
  $uniqueId: String
  $lastRunCount: Int
) {
  environment(id: $environmentId) {
    applied {
      modelHistoricalRuns(
        uniqueId: $uniqueId
        lastRunCount: $lastRunCount
      ) {
        name
        runId
        runElapsedTime
        runGeneratedAt
        executionTime
        executeStartedAt
        executeCompletedAt
        status
      }
    }
  }
}

**Examples:**

Example 1 (unknown):
```unknown
#### Contribute[​](#contribute "Direct link to Contribute")

To contribute to this project, check out our [contribution guidelines](https://github.com/dbt-labs/semantic-layer-sdk-python/blob/main/CONTRIBUTING.md) and open a GitHub [issue](https://github.com/dbt-labs/semantic-layer-sdk-python/issues) or [pull request](https://github.com/dbt-labs/semantic-layer-sdk-python/pulls).

#### Was this page helpful?

YesNo

[Privacy policy](https://www.getdbt.com/cloud/privacy-policy)[Create a GitHub issue](https://github.com/dbt-labs/docs.getdbt.com/issues)

This site is protected by reCAPTCHA and the Google [Privacy Policy](https://policies.google.com/privacy) and [Terms of Service](https://policies.google.com/terms) apply.


---

### Query the Discovery API

The Discovery API supports ad-hoc queries and integrations. If you are new to the API, refer to [About the Discovery API](https://docs.getdbt.com/docs/dbt-cloud-apis/discovery-api.md) for an introduction.

Use the Discovery API to evaluate data pipeline health and project state across runs or at a moment in time. dbt Labs provide a default [GraphQL explorer](https://metadata.cloud.getdbt.com/graphql) for this API, enabling you to run queries and browse the schema. However, you can also use any GraphQL client of your choice to query the API.

Since GraphQL describes the data in the API, the schema displayed in the GraphQL explorer accurately represents the graph and fields available to query.

#### Prerequisites[​](#prerequisites "Direct link to Prerequisites")

* dbt [multi-tenant](https://docs.getdbt.com/docs/cloud/about-cloud/tenancy.md#multi-tenant) or [single tenant](https://docs.getdbt.com/docs/cloud/about-cloud/tenancy.md#single-tenant) account
* You must be on an [Enterprise or Enterprise+ plan](https://www.getdbt.com/pricing/)
* Your projects must be on a dbt [release tracks](https://docs.getdbt.com/docs/dbt-versions/cloud-release-tracks.md) or dbt version 1.0 or later. Refer to [Upgrade dbt version in Cloud](https://docs.getdbt.com/docs/dbt-versions/upgrade-dbt-version-in-cloud.md) to upgrade.

#### Authorization[​](#authorization "Direct link to Authorization")

Currently, authorization of requests takes place [using a service token](https://docs.getdbt.com/docs/dbt-cloud-apis/service-tokens.md). dbt admin users can generate a Metadata Only service token that is authorized to execute a specific query against the Discovery API.

Once you've created a token, you can use it in the Authorization header of requests to the dbt Discovery API. Be sure to include the Token prefix in the Authorization header, or the request will fail with a `401 Unauthorized` error. Note that `Bearer` can be used instead of `Token` in the Authorization header. Both syntaxes are equivalent.

#### Access the Discovery API[​](#access-the-discovery-api "Direct link to Access the Discovery API")

1. Create a [service account token](https://docs.getdbt.com/docs/dbt-cloud-apis/service-tokens.md) to authorize requests. dbt Admin users can generate a *Metadata Only* service token, which can be used to execute a specific query against the Discovery API to authorize requests.

2. Find the API URL to use from the [Discovery API endpoints](#discovery-api-endpoints) table.

3. For specific query points, refer to the [schema documentation](https://docs.getdbt.com/docs/dbt-cloud-apis/discovery-schema-job.md).

#### Run queries using HTTP requests[​](#run-queries-using-http-requests "Direct link to Run queries using HTTP requests")

You can run queries by sending a `POST` request to the Discovery API, making sure to replace:

* `YOUR_API_URL` with the appropriate [Discovery API endpoint](#discovery-api-endpoints) for your region and plan.

* `YOUR_TOKEN` in the Authorization header with your actual API token. Be sure to include the Token prefix.

* `QUERY_BODY` with a GraphQL query, for example `{ "query": "<query text>", "variables": "<variables in json>" }`

* `VARIABLES` with a dictionary of your GraphQL query variables, such as a job ID or a filter.

* `ENDPOINT` with the endpoint you're querying, such as environment.
```

Example 2 (unknown):
```unknown
Python example:
```

Example 3 (unknown):
```unknown
Every query will require an environment ID or job ID. You can get the ID from a dbt URL or using the Admin API.

There are several illustrative example queries on this page. For more examples, refer to [Use cases and examples for the Discovery API](https://docs.getdbt.com/docs/dbt-cloud-apis/discovery-use-cases-and-examples.md).

#### Discovery API endpoints[​](#discovery-api-endpoints "Direct link to Discovery API endpoints")

The following are the endpoints for accessing the Discovery API. Use the one that's appropriate for your region and plan.

| Deployment type            | Discovery API URL                                                                                                                                                                                                                                            |
| -------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| North America multi-tenant | <https://metadata.cloud.getdbt.com/graphql>                                                                                                                                                                                                                  |
| EMEA multi-tenant          | <https://metadata.emea.dbt.com/graphql>                                                                                                                                                                                                                      |
| APAC multi-tenant          | <https://metadata.au.dbt.com/graphql>                                                                                                                                                                                                                        |
| Multi-cell                 | `https://YOUR_ACCOUNT_PREFIX.metadata.REGION.dbt.com/graphql`<br /><br />Replace `YOUR_ACCOUNT_PREFIX` with your specific account identifier and `REGION` with your location, which could be `us1.dbt.com`.                                                  |
| Single-tenant              | `https://metadata.YOUR_ACCESS_URL/graphql`<br /><br />Replace `YOUR_ACCESS_URL` with your specific account prefix with the appropriate [Access URL](https://docs.getdbt.com/docs/cloud/about-cloud/access-regions-ip-addresses.md) for your region and plan. |

#### Reasonable use[​](#reasonable-use "Direct link to Reasonable use")

Discovery (GraphQL) API usage is subject to request rate and response size limits to maintain the performance and stability of the metadata platform and prevent abuse.

Job-level endpoints are subject to query complexity limits. Nested nodes (like parents), code (like rawCode), and catalog columns are considered as most complex. Overly complex queries should be broken up into separate queries with only necessary fields included. dbt Labs recommends using the environment endpoint instead for most use cases to get the latest descriptive and result metadata for a dbt project.

#### Retention limits[​](#retention-limits "Direct link to Retention limits")

You can use the Discovery API to query data from the previous two months. For example, if today was April 1st, you could query data back to February 1st.

#### Run queries with the GraphQL explorer[​](#run-queries-with-the-graphql-explorer "Direct link to Run queries with the GraphQL explorer")

You can run ad-hoc queries directly in the [GraphQL API explorer](https://metadata.cloud.getdbt.com/graphql) and use the document explorer on the left-hand side to see all possible nodes and fields.

Refer to the [Apollo explorer documentation](https://www.apollographql.com/docs/graphos/explorer/explorer) for setup and authorization information for GraphQL.

1. Access the [GraphQL API explorer](https://metadata.cloud.getdbt.com/graphql) and select fields you want to query.

2. Select **Variables** at the bottom of the explorer and replace any `null` fields with your unique values.

3. [Authenticate](https://www.apollographql.com/docs/graphos/explorer/connecting-authenticating#authentication) using Bearer auth with `YOUR_TOKEN`. Select **Headers** at the bottom of the explorer and select **+New header**.

4. Select **Authorization** in the **header key** dropdown list and enter your Bearer auth token in the **value** field. Remember to include the Token prefix. Your header key should be in this format: `{"Authorization": "Bearer <YOUR_TOKEN>}`.

<br />

[![Enter the header key and Bearer auth token values](/img/docs/dbt-cloud/discovery-api/graphql_header.jpg?v=2 "Enter the header key and Bearer auth token values")](#)Enter the header key and Bearer auth token values

1. Run your query by clicking the blue query button in the top right of the **Operation** editor (to the right of the query). You should see a successful query response on the right side of the explorer.

[![Run queries using the Apollo Server GraphQL explorer](/img/docs/dbt-cloud/discovery-api/graphql.jpg?v=2 "Run queries using the Apollo Server GraphQL explorer")](#)Run queries using the Apollo Server GraphQL explorer

##### Fragments[​](#fragments "Direct link to Fragments")

Use the [`... on`](https://www.apollographql.com/docs/react/data/fragments/) notation to query across lineage and retrieve results from specific node types.
```

Example 4 (unknown):
```unknown
##### Pagination[​](#pagination "Direct link to Pagination")

Querying large datasets can impact performance on multiple functions in the API pipeline. Pagination eases the burden by returning smaller data sets one page at a time. This is useful for returning a particular portion of the dataset or the entire dataset piece-by-piece to enhance performance. dbt utilizes cursor-based pagination, which makes it easy to return pages of constantly changing data.

Use the `PageInfo` object to return information about the page. The available fields are:

* `startCursor` string type — Corresponds to the first `node` in the `edge`.
* `endCursor` string type — Corresponds to the last `node` in the `edge`.
* `hasNextPage` boolean type — Whether or not there are more `nodes` after the returned results.

There are connection variables available when making the query:

* `first` integer type — Returns the first n `nodes` for each page, up to 500.
* `after` string type — Sets the cursor to retrieve `nodes` after. It's best practice to set the `after` variable with the object ID defined in the `endCursor` of the previous page.

Below is an example that returns the `first` 500 models `after` the specified Object ID in the variables. The `PageInfo` object returns where the object ID where the cursor starts, where it ends, and whether there is a next page.

[![Example of pagination](/img/Paginate.png?v=2 "Example of pagination")](#)Example of pagination

Below is a code example of the `PageInfo` object:
```

---

## this job calls the dbt API to run a job

**URL:** llms-txt#this-job-calls-the-dbt-api-to-run-a-job

**Contents:**
  - Debug errors
  - Debug schema names
  - Get started with Continuous Integration tests

run-dbt-cloud-job:
  stage: build
  rules:
    - if: $CI_PIPELINE_SOURCE == "push" && $CI_COMMIT_BRANCH == 'main'
  script:
    - python python/run_and_monitor_dbt_job.py

trigger: [ main ] # runs on pushes to main

variables:
  DBT_URL:                 https://cloud.getdbt.com # no trailing backslash, adjust this accordingly for single-tenant deployments
  DBT_JOB_CAUSE:           'Azure Pipeline CI Job' # provide a descriptive job cause here for easier debugging down the road
  DBT_ACCOUNT_ID:          00000 # enter your account id
  DBT_PROJECT_ID:          00000 # enter your project id
  DBT_PR_JOB_ID:           00000 # enter your job id

steps:
  - task: UsePythonVersion@0
    inputs:
      versionSpec: '3.7'
    displayName: 'Use Python 3.7'

- script: |
      python -m pip install requests
    displayName: 'Install python dependencies'

- script: |
      python -u ./python/run_and_monitor_dbt_job.py
    displayName: 'Run dbt job '
    env:
      DBT_API_KEY: $(DBT_API_KEY) # Set these values as secrets in the Azure pipelines Web UI

pipelines:
  branches:
    'main': # override if your default branch doesn't run on a branch named "main"
      - step:
          name: 'Run dbt Job'
          script:
            - export DBT_URL="https://cloud.getdbt.com" # if you have a single-tenant deployment, adjust this accordingly
            - export DBT_JOB_CAUSE="Bitbucket Pipeline CI Job"
            - export DBT_ACCOUNT_ID=00000 # enter your account id here
            - export DBT_PROJECT_ID=00000 # enter your project id here
            - export DBT_PR_JOB_ID=00000 # enter your job id here
            - python python/run_and_monitor_dbt_job.py

pipelines:
  branches:
    '**': # this sets a wildcard to run on every branch unless specified by name below
      - step:
          name: Lint dbt project
          script:
            - python -m pip install sqlfluff==0.13.1
            - sqlfluff lint models --dialect snowflake --rules L019,L020,L021,L022

'main': # override if your default branch doesn't run on a branch named "main"
      - step:
          name: 'Run dbt Job'
          script:
            - export DBT_URL="https://cloud.getdbt.com" # if you have a single-tenant deployment, adjust this accordingly
            - export DBT_JOB_CAUSE="Bitbucket Pipeline CI Job"
            - export DBT_ACCOUNT_ID=00000 # enter your account id here
            - export DBT_PROJECT_ID=00000 # enter your project id here
            - export DBT_PR_JOB_ID=00000 # enter your job id here
            - python python/run_and_monitor_dbt_job.py

pipelines:
  # This job will run when pull requests are created in the repository
  pull-requests:
    '**':
      - step:
          name: 'Run dbt PR Job'
          script:
            # Check to only build if PR destination is master (or other branch). 
            # Comment or remove line below if you want to run on all PR's regardless of destination branch.
            - if [ "${BITBUCKET_PR_DESTINATION_BRANCH}" != "main" ]; then printf 'PR Destination is not master, exiting.'; exit; fi
            - export DBT_URL="https://cloud.getdbt.com"
            - export DBT_JOB_CAUSE="Bitbucket Pipeline CI Job"
            - export DBT_JOB_BRANCH=$BITBUCKET_BRANCH
            - export DBT_JOB_SCHEMA_OVERRIDE="DBT_CLOUD_PR_"$BITBUCKET_PROJECT_KEY"_"$BITBUCKET_PR_ID
            - export DBT_ACCOUNT_ID=00000 # enter your account id here
            - export DBT_PROJECT_ID=00000 # enter your project id here
            - export DBT_PR_JOB_ID=00000 # enter your job id here
            - python python/run_and_monitor_dbt_job.py

{# 
    This macro finds PR schemas older than a set date and drops them 
    The macro defaults to 10 days old, but can be configured with the input argument age_in_days
    Sample usage with different date:
        dbt run-operation pr_schema_cleanup --args "{'database_to_clean': 'analytics','age_in_days':'15'}"
#}
{% macro pr_schema_cleanup(database_to_clean, age_in_days=10) %}

{% set find_old_schemas %}
        select 
            'drop schema {{ database_to_clean }}.'||schema_name||';'
        from {{ database_to_clean }}.information_schema.schemata
        where
            catalog_name = '{{ database_to_clean | upper }}'
            and schema_name ilike 'DBT_CLOUD_PR%'
            and last_altered <= (current_date() - interval '{{ age_in_days }} days')
    {% endset %}

{{ log('Schema drop statements:' ,True) }}

{% set schema_drop_list = run_query(find_old_schemas).columns[0].values() %}

{% for schema_to_drop in schema_drop_list %}
            {% do run_query(schema_to_drop) %}
            {{ log(schema_to_drop ,True) }}
        {% endfor %}

Running with dbt=1.7.1
Encountered an error:
Runtime Error
  fatal: Not a dbt project (or any of the parent directories). Missing dbt_project.yml file

Running with dbt=1.7.1

Encountered an error:
Runtime Error
  Could not run dbt
  Could not find profile named 'jaffle_shops'

profile: jaffle_shops # note the plural

jaffle_shop: # this does not match the profile: key
  target: dev

outputs:
    dev:
      type: postgres
      schema: dbt_alice
      ... # other connection details

$ dbt debug --config-dir
Running with dbt=1.7.1
To view your profiles.yml file, run:

open /Users/alice/.dbt

Encountered an error:
Runtime Error
  Database error while listing schemas in database "analytics"
  Database Error
    250001 (08001): Failed to connect to DB: your_db.snowflakecomputing.com:443. Incorrect username or password was specified.

$ dbt debug
Running with dbt=1.7.1
Using profiles.yml file at /Users/alice/.dbt/profiles.yml
Using dbt_project.yml file at /Users/alice/jaffle-shop-dbt/dbt_project.yml

Configuration:
  profiles.yml file [OK found and valid]
  dbt_project.yml file [OK found and valid]

Required dependencies:
 - git [OK found]

Connection:
  ...
  Connection test: OK connection ok

Encountered an error while reading the project:
  ERROR: Runtime Error
  at path []: Additional properties are not allowed ('hello' was unexpected)

Error encountered in /Users/alice/jaffle-shop-dbt/dbt_project.yml
Encountered an error:
Runtime Error
  Could not run dbt

name: jaffle_shop
hello: world # this is not allowed

$ dbt run -s customers
Running with dbt=1.1.0

Encountered an error:
Compilation Error in model customers (models/customers.sql)
  Model 'model.jaffle_shop.customers' (models/customers.sql) depends on a node named 'stg_customer' which was not found

$ dbt run
Running with dbt=1.7.1
Compilation Error in macro (macros/cents_to_dollars.sql)
  Reached EOF without finding a close tag for macro (searched from line 1)

$ dbt run
Running with dbt=1.7.1

Encountered an error:
Compilation Error
  Error reading jaffle_shop: schema.yml - Runtime Error
    Syntax error near line 5
    ------------------------------
    2  |
    3  | models:
    4  | - name: customers
    5  |     columns:
    6  |       - name: customer_id
    7  |         data_tests:
    8  |           - unique

Raw Error:
    ------------------------------
    mapping values are not allowed in this context
      in "<unicode string>", line 5, column 12

models:
  - name: customers
      columns: # this is indented too far!
      - name: customer_id
        data_tests:
          - unique
          - not_null

$ dbt run
Running with dbt=1.7.1

Encountered an error:
Compilation Error
  Invalid models config given in models/schema.yml @ models: {'name': 'customers', 'hello': 'world', 'columns': [{'name': 'customer_id', 'tests': ['unique', 'not_null']}], 'original_file_path': 'models/schema.yml', 'yaml_key': 'models', 'package_name': 'jaffle_shop'} - at path []: Additional properties are not allowed ('hello' was unexpected)

$ dbt run
Running with dbt=1.7.1-rc

Encountered an error:
Found a cycle: model.jaffle_shop.customers --> model.jaffle_shop.stg_customers --> model.jaffle_shop.customers

$ dbt run
...
Completed with 1 error and 0 warnings:

Database Error in model customers (models/customers.sql)
  001003 (42000): SQL compilation error:
  syntax error line 14 at position 4 unexpected 'from'.
  compiled SQL at target/run/jaffle_shop/models/customers.sql

target/
  dbt_packages/
  logs/
  # legacy -- renamed to dbt_packages in dbt v1
  dbt_modules/
  
  Running with dbt=xxx
  Runtime Error
    Failed to read package: Runtime Error
      Invalid config version: 1, expected 2  
    Error encountered in dbt_utils/dbt_project.yml
  
  packages:
  - package: dbt-labs/dbt_utils

version: xxx
  
  Compilation Error
    In dispatch: Could not find package 'my_project'
  
  $ dbt run --select customers
  Running with dbt=1.9.0
  Found 3 models, 9 tests, 0 snapshots, 0 analyses, 133 macros, 0 operations, 0 seed files, 0 sources

14:04:12 | Concurrency: 1 threads (target='dev')
  14:04:12 |
  14:04:12 | 1 of 1 START view model dbt_alice.customers.......................... [RUN]
  14:04:13 | 1 of 1 ERROR creating view model dbt_alice.customers................. [ERROR in 0.81s]
  14:04:13 |
  14:04:13 | Finished running 1 view model in 1.68s.

Completed with 1 error and 0 warnings:

Database Error in model customers (models/customers.sql)
    Syntax error: Expected ")" but got identifier `your-info-12345` at [13:15]
    compiled SQL at target/run/jaffle_shop/customers.sql

Done. PASS=0 WARN=0 ERROR=1 SKIP=0 TOTAL=1
  
{% macro generate_schema_name(custom_schema_name, node) -%}

{%- set default_schema = target.schema -%}
    {%- if custom_schema_name is none -%}

{{ default_schema }}_{{ custom_schema_name | trim }}

{% macro generate_schema_name(custom_schema_name, node) -%}
    {{ generate_schema_name_for_env(custom_schema_name, node) }}
{%- endmacro %}

{% macro generate_schema_name_for_env(custom_schema_name, node) -%}

{%- set default_schema = target.schema -%}
    {%- if target.name == 'prod' and custom_schema_name is not none -%}

{{ custom_schema_name | trim }}

data_tests:
dbt_project_evaluator:
    +severity: "{{ env_var('DBT_PROJECT_EVALUATOR_SEVERITY', 'warn') }}"

dbt build --select state:modified+ --exclude package:dbt_project_evaluator
dbt build --select package:dbt_project_evaluator

my_awesome_project
├── .github
│   ├── workflows
│   │   └── lint_on_push.yml

name: lint dbt project on push

on:
  push:
    branches-ignore:
      - 'main'

jobs:
  # this job runs SQLFluff with a specific set of rules
  # note the dialect is set to Snowflake, so make that specific to your setup
  # details on linter rules: https://docs.sqlfluff.com/en/stable/rules.html
  lint_project:
    name: Run SQLFluff linter
    runs-on: ubuntu-latest
  
    steps:
      - uses: "actions/checkout@v3"
      - uses: "actions/setup-python@v4"
        with:
          python-version: "3.9"
      - name: Install SQLFluff
        run: "python -m pip install sqlfluff"
      - name: Lint project
        run: "sqlfluff lint models --dialect snowflake"

my_awesome_project
├── dbt_project.yml
├── .gitlab-ci.yml

stages:
  - pre-build

**Examples:**

Example 1 (unknown):
```unknown
For this new job, open the existing Azure pipeline you created above and select the *Edit* button. We'll want to edit the corresponding Azure pipeline YAML file with the appropriate configuration, instead of the starter code, along with including a `variables` section to pass in the required variables.

Copy the below YAML file into your Azure pipeline and update the variables below to match your setup based on the comments in the file. It's worth noting that we changed the `trigger` section so that it will run **only** when there are pushes to a branch named `main` (like a PR merged to your main branch).

Read through [Azure's docs](https://learn.microsoft.com/en-us/azure/devops/pipelines/build/triggers?view=azure-devops) on these filters for additional use cases.
```

Example 2 (unknown):
```unknown
For this job, we'll set it up using the `bitbucket-pipelines.yml` file as in the prior step (see Step 1 of the linting setup for more info). The YAML file will look pretty similar to our earlier job, but we’ll pass in the required variables to the Python script using `export` statements. Update this section to match your setup based on the comments in the file.

* Only job
* Lint and dbt job
```

Example 3 (unknown):
```unknown

```

Example 4 (unknown):
```unknown
##### 5. Test your new action[​](#5-test-your-new-action "Direct link to 5. Test your new action")

Now that you have a shiny new action, it’s time to test it out! Since this change is setup to only run on merges to your default branch, you’ll need to create and merge this change into your main branch. Once you do that, you’ll see a new pipeline job has been triggered to run the dbt job you assigned in the variables section.

Additionally, you’ll see the job in the run history of dbt. It should be fairly easy to spot because it will say it was triggered by the API, and the *INFO* section will have the branch you used for this guide.

* GitHub
* GitLab
* Azure DevOps
* Bitbucket

[![dbt run on merge job in GitHub](/img/guides/orchestration/custom-cicd-pipelines/dbt-run-on-merge-github.png?v=2 "dbt run on merge job in GitHub")](#)dbt run on merge job in GitHub

[![dbt job showing it was triggered by GitHub](/img/guides/orchestration/custom-cicd-pipelines/dbt-cloud-job-github-triggered.png?v=2 "dbt job showing it was triggered by GitHub")](#)dbt job showing it was triggered by GitHub

[![dbt run on merge job in GitLab](/img/guides/orchestration/custom-cicd-pipelines/dbt-run-on-merge-gitlab.png?v=2 "dbt run on merge job in GitLab")](#)dbt run on merge job in GitLab

[![dbt job showing it was triggered by GitLab](/img/guides/orchestration/custom-cicd-pipelines/dbt-cloud-job-gitlab-triggered.png?v=2 "dbt job showing it was triggered by GitLab")](#)dbt job showing it was triggered by GitLab

[![dbt run on merge job in ADO](/img/guides/orchestration/custom-cicd-pipelines/dbt-run-on-merge-azure.png?v=2 "dbt run on merge job in ADO")](#)dbt run on merge job in ADO

[![ADO-triggered job in dbt](/img/guides/orchestration/custom-cicd-pipelines/dbt-cloud-job-azure-triggered.png?v=2 "ADO-triggered job in dbt")](#)ADO-triggered job in dbt

[![dbt run on merge job in Bitbucket](/img/guides/orchestration/custom-cicd-pipelines/dbt-run-on-merge-bitbucket.png?v=2 "dbt run on merge job in Bitbucket")](#)dbt run on merge job in Bitbucket

[![dbt job showing it was triggered by Bitbucket](/img/guides/orchestration/custom-cicd-pipelines/dbt-cloud-job-bitbucket-triggered.png?v=2 "dbt job showing it was triggered by Bitbucket")](#)dbt job showing it was triggered by Bitbucket

#### Run a dbt job on pull request[​](#run-a-dbt-job-on-pull-request "Direct link to Run a dbt job on pull request")

If your git provider is not one with a native integration with dbt, but you still want to take advantage of CI builds, you've come to the right spot! With just a bit of work it's possible to setup a job that will run a dbt job when a pull request (PR) is created.

Run on PR

If your git provider has a native integration with dbt, you can take advantage of the setup instructions [here](https://docs.getdbt.com/docs/deploy/ci-jobs.md). This section is only for those projects that connect to their git repository using an SSH key.

The setup for this pipeline will use the same steps as the prior page. Before moving on, follow steps 1-5 from the [prior page](https://docs.getdbt.com/guides/custom-cicd-pipelines.md?step=2).

##### 1. Create a pipeline job that runs when PRs are created[​](#1-create-a-pipeline-job-that-runs-when-prs-are-created "Direct link to 1. Create a pipeline job that runs when PRs are created")

* Bitbucket

For this job, we'll set it up using the `bitbucket-pipelines.yml` file as in the prior step. The YAML file will look pretty similar to our earlier job, but we’ll pass in the required variables to the Python script using `export` statements. Update this section to match your setup based on the comments in the file.

**What is this pipeline going to do?**<br /><!-- -->The setup below will trigger a dbt job to run every time a PR is opened in this repository. It will also run a fresh version of the pipeline for every commit that is made on the PR until it is merged. For example: If you open a PR, it will run the pipeline. If you then decide additional changes are needed, and commit/push to the PR branch, a new pipeline will run with the updated code.

The following variables control this job:

* `DBT_JOB_BRANCH`: Tells the dbt job to run the code in the branch that created this PR
* `DBT_JOB_SCHEMA_OVERRIDE`: Tells the dbt job to run this into a custom target schema
  <!-- -->
  * The format of this will look like: `DBT_CLOUD_PR_{REPO_KEY}_{PR_NUMBER}`
```

---

## In this example we set up a secret scope and key called "dbt-cloud" and "api-key" respectively.

**URL:** llms-txt#in-this-example-we-set-up-a-secret-scope-and-key-called-"dbt-cloud"-and-"api-key"-respectively.

databricks secrets create-scope --scope <YOUR_SECRET_SCOPE>
databricks secrets put --scope  <YOUR_SECRET_SCOPE> --key  <YOUR_SECRET_KEY> --string-value "<YOUR_DBT_CLOUD_API_KEY>"

import enum
import os
import time
import json
import requests
from getpass import getpass
     
dbutils.widgets.text("job_id", "Enter the Job ID")
job_id = dbutils.widgets.get("job_id")

account_id = <YOUR_ACCOUNT_ID>
base_url =  "<YOUR_BASE_URL>"
api_key =  dbutils.secrets.get(scope = "<YOUR_SECRET_SCOPE>", key = "<YOUR_SECRET_KEY>")

**Examples:**

Example 1 (unknown):
```unknown
4. Replace **`<YOUR_SECRET_SCOPE>`** and **`<YOUR_SECRET_KEY>`** with your own unique identifiers. Click [here](https://docs.databricks.com/security/secrets/index.html) for more information on secrets.

5. Replace **`<YOUR_DBT_CLOUD_API_KEY>`** with the actual API key value that you copied from dbt in step 1.

#### Create a Databricks Python notebook[​](#create-a-databricks-python-notebook "Direct link to Create a Databricks Python notebook")

1. [Create a **Databricks Python notebook**](https://docs.databricks.com/notebooks/notebooks-manage.html), which executes a Python script that calls the dbt job API.

2. Write a **Python script** that utilizes the `requests` library to make an HTTP POST request to the dbt job API endpoint using the required parameters. Here's an example script:
```

---

## Fetch run info from the dbt Admin API

**URL:** llms-txt#fetch-run-info-from-the-dbt-admin-api

url = f'https://YOUR_ACCESS_URL/api/v2/accounts/{account_id}/runs/{run_id}/?include_related=["run_steps"]'
headers = {'Authorization': f'Token {api_token}'}
run_data_response = requests.get(url, headers=headers)
run_data_response.raise_for_status()
run_data_results = run_data_response.json()['data']

---

## Set API key

**URL:** llms-txt#set-api-key

auth_token = *[SERVICE_TOKEN_HERE]*

---

## Query the API

**URL:** llms-txt#query-the-api

def query_discovery_api(auth_token, gql_query, variables):
    response = requests.post('https://metadata.cloud.getdbt.com/graphql',
        headers={"authorization": "Bearer "+auth_token, "content-type": "application/json"},
        json={"query": gql_query, "variables": variables})
    data = response.json()['data']

---

## Define second query variables

**URL:** llms-txt#define-second-query-variables

variables_query_two = {
    "environmentId": *[ENVR_ID_HERE]*
    "lastRunCount": 10,
    "uniqueId": longest_running_model
}

---
