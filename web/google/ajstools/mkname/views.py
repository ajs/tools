from django.template import Context, loader
from django.http import HttpResponse

SITE_TITLE='Random Names List Generator'

def sample(request):
    tmp = loader.get_template('mkname/sample.html')
    return HttpResponse(tmp.render(Context({
                    'title':SITE_TITLE,
                    })))

def lang(request, language):
    tmp = loader.get_template('mkname/lang.html')
    return HttpResponse(tmp.render(Context({
                    'title':"%s: %s"%(SITE_TITLE, str(language).title()),
                    'language':language,
                    })))

def lang_extra(request, language, extra):
    tmp = loader.get_template('mkname/lang_extra.html')
    return HttpResponse(tmp.render(Context({
                    'title':"%s: %s/%s"%(SITE_TITLE, str(language).title(), str(extra).title()),
                    'language':language,
                    'extra':extra,
                    })))
