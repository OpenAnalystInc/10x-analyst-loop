# 10x.in PAT Scopes Reference

## Full-Access Scope String (copy-paste into PAT creation)

```
mcp.connect, links.*, skills.read, skill.invoke:*, analytics.*, webhooks.*, tracking.templates.*, tracking.personalization.*, routing.context_origins.*, chain.*, agent.*, qa.*, knowledge.query:*, knowledge.write, registry.write, system.*, usage.read, audit.read
```

## Scope Categories

### Core
| Scope | Access |
|-------|--------|
| `mcp.connect` | Connect to MCP server |
| `skills.read` | Read available skills |
| `skill.invoke:*` | Invoke any skill |

### Links
| Scope | Access |
|-------|--------|
| `links.read` | List/read links |
| `links.write` | Create/update/delete links |
| `links.*` | All link operations |

### Analytics
| Scope | Access |
|-------|--------|
| `analytics.read` | Read analytics data |
| `analytics.*` | All analytics (get, export, campaign health) |

### Webhooks
| Scope | Access |
|-------|--------|
| `webhooks.read` | List webhook subscriptions |
| `webhooks.write` | Create/delete/test webhooks |
| `webhooks.*` | All webhook operations |

### Tracking
| Scope | Access |
|-------|--------|
| `tracking.templates.read` | List tracking templates |
| `tracking.templates.write` | Create/update templates |
| `tracking.templates.*` | All template operations |
| `tracking.personalization.read` | List personalization rules |
| `tracking.personalization.write` | Create/update rules |
| `tracking.personalization.*` | All personalization operations |

### Routing / Chain
| Scope | Access |
|-------|--------|
| `routing.context_origins.read` | Read context origins |
| `routing.context_origins.write` | Update context origins |
| `routing.context_origins.*` | All routing operations |
| `chain.read` | Read chain sessions |
| `chain.resolve.read` | Resolve chain decisions |
| `chain.signal.write` | Write chain signals |
| `chain.*` | All chain operations |

### Agent
| Scope | Access |
|-------|--------|
| `agent.discover.read` | Run agent discovery |
| `agent.strategy.read` | Read strategy recommendations |
| `agent.strategy.write` | Generate strategies |
| `agent.proposal.read` | List proposals |
| `agent.proposal.write` | Create proposals |
| `agent.run.execute` | Start/rollback runs |
| `agent.run.read` | Get run status |
| `agent.recommendations.read` | Read recommendations |
| `agent.*` | All agent operations |

### QA
| Scope | Access |
|-------|--------|
| `qa.env.read` | Read QA environments |
| `qa.env.write` | Manage QA environments |
| `qa.suite.read` | Read QA suites |
| `qa.suite.write` | Manage QA suites |
| `qa.run.execute` | Execute QA runs |
| `qa.run.read` | Read QA run results |
| `qa.runner.work` | QA runner worker |
| `qa.*` | All QA operations |

### Knowledge
| Scope | Access |
|-------|--------|
| `knowledge.query` | Query knowledge base |
| `knowledge.query:*` | Query all knowledge topics |
| `knowledge.write` | Write knowledge documents |

### Registry
| Scope | Access |
|-------|--------|
| `registry.read` | Read registry entries |
| `registry.write` | Write registry entries (also grants knowledge.write) |

### System
| Scope | Access |
|-------|--------|
| `system.*` | All system operations |
| `usage.read` | Read usage meters |
| `audit.read` | Read audit events |

### Wildcard
| Scope | Access |
|-------|--------|
| `*` | Full unrestricted access (all scopes) |
