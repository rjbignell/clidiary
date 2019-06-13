
drop table diary_projects;

create table diary_projects (
	projcode	character varying(6),
	projname	character varying(80)
);

\copy diary_projects from 'projects.csv' with delimiter as ',' null as ''

drop table diary_tasks;

create table diary_tasks (
	projcode	character varying(6),
	acticode	character varying(6),
	actiname	character varying(80)
);

\copy diary_tasks from 'tasks.csv' with delimiter as ',' null as ''

drop table diary_activities;

create table diary_activities as
  select diary_projects.projcode, projname, acticode, actiname
  from diary_projects, diary_tasks
  where diary_projects.projcode = diary_tasks.projcode
  order by diary_projects.projcode, acticode;

\copy diary_activities to 'activities.csv' with delimiter as ',' null as ''

drop table diary_daydata;

create table diary_daydata (
	datadate	date,
	datatime	character varying(6),
	projcode	character varying(6),
	acticode	character varying(6)
);

